use std::fmt::Debug;

use anyhow::{Context, Result, anyhow};
use html_to_markdown_rs::{ConversionOptions, InlineDataMedia, PreprocessingOptions};
use serde::Deserialize;
use serde_json::json;
use surrealdb_types::{Bytes, RecordId, SurrealValue, object};
use surrealism::{Transaction, surrealism};
use url::Url;

// HTTP goes through ureq rather than `http::*`: SurrealDB returns NONE for any content type other
// than JSON, text or octet-stream (so images never come through), and discards error bodies.
#[surrealism]
async fn scrape_for_recipe(
    tx: Transaction,
    household: RecordId,
    source_type: String,
    source_text: String,
) -> Result<RecipeInfo> {
    let (text, page_url) = if source_type == "text" {
        (source_text, None)
    } else if source_type == "url" {
        let html = ureq::get(&source_text)
            .call()
            .and_then(|mut response| response.body_mut().read_to_string())
            .context("Failed to fetch the recipe page")?;

        (html_to_markdown(&html, &source_text)?, Some(source_text))
    } else {
        return Err(anyhow!("Invalid source type"));
    };

    let response = call_ai(&tx, &text).await?;

    let mut info: RecipeInfo = serde_json::de::from_str(&response.choices[0].message.content)?;

    if let (Some(image_url), Some(page_url)) = (&info.image_url, &page_url) {
        info.image = fetch_image(page_url, image_url);
    }

    for info in &mut info.ingredients {
        info.ingredient = find_by_name(&tx, &household, "ingredient", info.name.clone()).await?;

        if let Some(unit_string) = &info.unit_string {
            info.unit = find_by_name(&tx, &household, "unit", unit_string.clone()).await?;
        }
    }

    if let Some(cuisine_string) = &info.cuisine_string {
        info.cuisine = find_by_name(&tx, &household, "cuisine", cuisine_string.clone()).await?;
    }

    for tag_string in &info.tag_strings {
        if let Some(tag) = find_by_name(&tx, &household, "recipe_tag", tag_string.clone()).await? {
            info.tags.push(tag);
        }
    }

    for meal_string in &info.meal_strings {
        if let Some(meal) = find_by_name(&tx, &household, "meal", meal_string.clone()).await? {
            info.meals.push(meal);
        }
    }

    Ok(info)
}

/// Images inside links and table cells are only kept if their tag is in `keep_inline_images_in`,
/// recipe cards and photo grids are usually wrapped in one of those.
fn html_to_markdown(html: &str, page_url: &str) -> Result<String> {
    let options = ConversionOptions {
        base_url: Some(page_url.to_string()),
        keep_inline_images_in: vec!["a".into(), "td".into(), "th".into()],
        inline_data_media: InlineDataMedia::DropElement,
        preprocessing: PreprocessingOptions {
            enabled: true,
            remove_navigation: true,
            ..Default::default()
        },
        ..Default::default()
    };

    let result = html_to_markdown_rs::convert(html, Some(options))?;
    Ok(result.content.unwrap_or_default())
}

/// Fetched here rather than in the browser, because most image hosts don't send CORS headers.
/// Returns `None` on any failure, a missing image must not fail the whole import.
fn fetch_image(page_url: &str, image_url: &str) -> Option<Bytes> {
    // `base_url` makes the converter's image links absolute, but the og:image in the metadata
    // header is left as the page wrote it, which may be relative.
    let image_url = Url::parse(page_url).ok()?.join(image_url).ok()?;

    let mut response = ureq::get(image_url.as_str()).call().ok()?;
    let bytes = response.body_mut().read_to_vec().ok()?;

    Some(Bytes::from(bytes))
}

async fn call_ai(tx: &Transaction, text: &str) -> Result<AiResult> {
    let base_url: String = tx.sql("$openAiBaseUrl").await?;
    let model: String = tx.sql("$openAiModel").await?;
    let token: String = tx.sql("$openAiToken").await?;

    // Status errors are handled by hand, so the provider's explanation ends up in the error.
    let mut response = ureq::post(format!("{base_url}/v1/chat/completions"))
        .config()
        .http_status_as_error(false)
        .build()
        .header("Authorization", format!("Bearer {token}"))
        .send_json(json!({
            "model": model,
            "messages": [
                { "role": "system", "content": SYSTEM_PROMPT },
                { "role": "user", "content": text },
            ],
            "stream": false,
            "response_format": { "type": "json_object" },
        }))
        .context("Failed to call the AI API")?;

    if !response.status().is_success() {
        let body = response.body_mut().read_to_string().unwrap_or_default();
        return Err(anyhow!("AI API returned {}: {body}", response.status()));
    }

    Ok(response.body_mut().read_json()?)
}

async fn find_by_name(
    tx: &Transaction,
    household: &RecordId,
    table: &str,
    name: String,
) -> Result<Option<RecordId>> {
    let result: Option<RecordId> = tx
        .sql_with_vars(
            format!(
                "SELECT VALUE id FROM ONLY {table} WHERE name @@ $name && household = $household LIMIT 1"
            ),
            object! {
                name: name,
                household: household.clone()
            },
        )
        .await?;

    Ok(result)
}

#[derive(Debug, SurrealValue, Deserialize)]
struct Ingredient {
    name: String,
    amount: Option<f32>,
    unit_string: Option<String>,
    description: Option<String>,
    ingredient: Option<RecordId>,
    unit: Option<RecordId>,
}

#[derive(Debug, SurrealValue, Deserialize)]
struct RecipeInfo {
    name: Option<String>,
    portions: Option<i32>,
    ingredients: Vec<Ingredient>,
    steps: Vec<String>,
    cuisine_string: Option<String>,
    cuisine: Option<RecordId>,
    cooking_time_minutes: Option<i32>,
    #[serde(default)]
    tag_strings: Vec<String>,
    #[serde(default)]
    tags: Vec<RecordId>,
    #[serde(default)]
    meal_strings: Vec<String>,
    #[serde(default)]
    meals: Vec<RecordId>,
    image_url: Option<String>,
    #[serde(skip)]
    image: Option<Bytes>,
}

#[derive(Debug, Deserialize)]
struct AiResult {
    choices: Vec<AiChoice>,
}

#[derive(Debug, Deserialize)]
struct AiChoice {
    message: AiMessage,
}

#[derive(Debug, Deserialize)]
struct AiMessage {
    content: String,
}

const SYSTEM_PROMPT: &str = r#"You are a recipe data extraction assistant. Extract recipe information from website text content and return ONLY a raw JSON object.

The JSON must match this exact schema:
{
  "name": string or null,
  "portions": number or null,
  "ingredients": [
    {
      "name": string,
      "amount": number or null,
      "unit_string": string or null,
      "description": string or null
    }
  ],
  "steps": [string],
  "cuisine_string": string or null,
  "cooking_time_minutes": integer or null,
  "tag_strings": [string],
  "meal_strings": [string],
  "image_url": string or null
}

Guidelines:
- Keep all text in the language of the source
- For ingredients, separate into components:
  * "2 cups flour" → name:"flour", amount:"2", unit_string:"cups", description:null
  * "1 large diced onion" → name:"onion", amount:"1", unit_string:null, description:"large, diced"
  * "Salt to taste" → name:"salt", amount:null, unit_string:null, description:"to taste"
  * "3 tbsp chopped fresh parsley" → name:"parsley", amount:"3", unit_string:"tbsp", description:"chopped, fresh"
- Use description field for preparation methods (diced, chopped, minced), state (fresh, dried), and special notes (to taste, optional)
- Extract all step-by-step instructions in order
- Identify the cuisine type (e.g., "Italian", "Mexican", "Asian")
- Identify relevant tags found in the source (e.g., "vegetarian", "gluten-free", "quick")
- Identify meal types found in the source (e.g., "breakfast", "lunch", "dinner", "dessert")
- Images appear in the source as ![alt text](url). For image_url pick the one showing the finished dish of this recipe, copying its url exactly. Ignore logos, ads, author photos and images of other recipes; use null if unsure
- The page's social preview image appears as the meta-og:image line of the metadata header; it is often but not always the photo of the dish, and can be used as image_url
- cooking_time_minutes should be total time (prep + cook)
- Return empty arrays [] for missing list fields, null for missing singular fields"#;
