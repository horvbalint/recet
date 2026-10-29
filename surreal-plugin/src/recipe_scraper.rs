use std::fmt::Debug;

use anyhow::{Result, anyhow};
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
            .map_err(|err| anyhow!("Failed to fetch the recipe page: {err}"))?;

        (html_to_markdown(&html, &source_text)?, Some(source_text))
    } else {
        return Err(anyhow!("Invalid source type"));
    };

    let lists = HouseholdLists::load(&tx, &household).await?;
    let user_message = format!(
        "# Household lists\n\n{}\n# Recipe source\n\n{text}",
        lists.to_prompt()
    );

    let response = call_ai(&tx, &user_message).await?;
    let recipe: AiRecipe = serde_json::from_str(&response.choices[0].message.content)?;

    let image = match (&recipe.image_url, &page_url) {
        (Some(image_url), Some(page_url)) => fetch_image(page_url, image_url),
        _ => None,
    };

    Ok(RecipeInfo {
        name: recipe.name,
        portions: recipe.portions,
        ingredients: recipe
            .ingredients
            .into_iter()
            .map(|ingredient| Ingredient {
                ingredient: resolve(&lists.ingredients, ingredient.ingredient_id),
                unit: resolve(&lists.units, ingredient.unit_id),
                name: ingredient.name,
                amount: ingredient.amount,
                unit_string: ingredient.unit_string,
                description: ingredient.description,
            })
            .collect(),
        steps: recipe.steps,
        cuisine: resolve(&lists.cuisines, recipe.cuisine_id),
        cuisine_string: recipe.cuisine_string,
        cooking_time_minutes: recipe.cooking_time_minutes,
        tags: resolve_all(&lists.tags, &recipe.tag_ids),
        tag_strings: recipe.tag_strings,
        meals: resolve_all(&lists.meals, &recipe.meal_ids),
        meal_strings: recipe.meal_strings,
        image,
    })
}

/// The AI refers to entries by their index in these lists rather than by record id: indexes are
/// easy to copy, and one that is out of range simply resolves to no match.
struct HouseholdLists {
    ingredients: Vec<ListItem>,
    units: Vec<ListItem>,
    cuisines: Vec<ListItem>,
    tags: Vec<ListItem>,
    meals: Vec<ListItem>,
}

impl HouseholdLists {
    async fn load(tx: &Transaction, household: &RecordId) -> Result<Self> {
        Ok(Self {
            ingredients: load_list(tx, household, "ingredient").await?,
            units: load_list(tx, household, "unit").await?,
            cuisines: load_list(tx, household, "cuisine").await?,
            tags: load_list(tx, household, "recipe_tag").await?,
            meals: load_list(tx, household, "meal").await?,
        })
    }

    fn to_prompt(&self) -> String {
        [
            ("ingredients", &self.ingredients),
            ("units", &self.units),
            ("cuisines", &self.cuisines),
            ("tags", &self.tags),
            ("meals", &self.meals),
        ]
        .into_iter()
        .map(|(title, items)| {
            let entries: Vec<String> = items
                .iter()
                .enumerate()
                .map(|(index, item)| format!("{index}: {}", item.name))
                .collect();

            format!("## {title}\n{}\n", entries.join("\n"))
        })
        .collect::<Vec<_>>()
        .join("\n")
    }
}

#[derive(Debug, SurrealValue)]
struct ListItem {
    id: RecordId,
    name: String,
}

async fn load_list(tx: &Transaction, household: &RecordId, table: &str) -> Result<Vec<ListItem>> {
    tx.sql_with_vars(
        format!("SELECT id, name FROM {table} WHERE household = $household ORDER BY name"),
        object! {
            household: household.clone()
        },
    )
    .await
}

fn resolve(items: &[ListItem], index: Option<usize>) -> Option<RecordId> {
    index
        .and_then(|index| items.get(index))
        .map(|item| item.id.clone())
}

fn resolve_all(items: &[ListItem], indexes: &[usize]) -> Vec<RecordId> {
    indexes
        .iter()
        .filter_map(|&index| resolve(items, Some(index)))
        .collect()
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

async fn call_ai(tx: &Transaction, user_message: &str) -> Result<AiResult> {
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
                { "role": "user", "content": user_message },
            ],
            "stream": false,
            "response_format": { "type": "json_object" },
        }))
        .map_err(|err| anyhow!("Failed to call the AI API: {err}"))?;

    if !response.status().is_success() {
        let body = response.body_mut().read_to_string().unwrap_or_default();
        return Err(anyhow!("AI API returned {}: {body}", response.status()));
    }

    Ok(response.body_mut().read_json()?)
}

#[derive(Debug, SurrealValue)]
struct Ingredient {
    name: String,
    amount: Option<f32>,
    unit_string: Option<String>,
    description: Option<String>,
    ingredient: Option<RecordId>,
    unit: Option<RecordId>,
}

#[derive(Debug, SurrealValue)]
struct RecipeInfo {
    name: Option<String>,
    portions: Option<i32>,
    ingredients: Vec<Ingredient>,
    steps: Vec<String>,
    cuisine_string: Option<String>,
    cuisine: Option<RecordId>,
    cooking_time_minutes: Option<i32>,
    tag_strings: Vec<String>,
    tags: Vec<RecordId>,
    meal_strings: Vec<String>,
    meals: Vec<RecordId>,
    image: Option<Bytes>,
}

#[derive(Debug, Deserialize)]
struct AiIngredient {
    name: String,
    amount: Option<f32>,
    unit_string: Option<String>,
    description: Option<String>,
    ingredient_id: Option<usize>,
    unit_id: Option<usize>,
}

#[derive(Debug, Deserialize)]
struct AiRecipe {
    name: Option<String>,
    portions: Option<i32>,
    ingredients: Vec<AiIngredient>,
    steps: Vec<String>,
    cuisine_string: Option<String>,
    cuisine_id: Option<usize>,
    cooking_time_minutes: Option<i32>,
    #[serde(default)]
    tag_strings: Vec<String>,
    #[serde(default)]
    tag_ids: Vec<usize>,
    #[serde(default)]
    meal_strings: Vec<String>,
    #[serde(default)]
    meal_ids: Vec<usize>,
    image_url: Option<String>,
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

const SYSTEM_PROMPT: &str = r##"You are a recipe data extraction assistant. Return ONLY a raw JSON object, without any other text.

The user message has two parts:
1. "# Household lists": the household's own ingredients, units, cuisines, tags and meals, each entry written as `index: name`
2. "# Recipe source": the recipe in Markdown, converted from a web page or pasted by the user

Work in two separate steps: first extract the recipe from the source, then match the extracted values to the household lists. The household lists are used for the *_id fields only.

The JSON must match this exact schema:
{
  "name": string or null,
  "portions": number or null,
  "ingredients": [
    {
      "name": string,
      "amount": number or null,
      "unit_string": string or null,
      "description": string or null,
      "ingredient_id": integer or null,
      "unit_id": integer or null
    }
  ],
  "steps": [string],
  "cuisine_string": string or null,
  "cuisine_id": integer or null,
  "cooking_time_minutes": integer or null,
  "tag_strings": [string],
  "tag_ids": [integer],
  "meal_strings": [string],
  "meal_ids": [integer],
  "image_url": string or null
}

Step 1 - extraction, from the recipe source only:
- Every text field (name, ingredient name, unit_string, description, steps, cuisine_string, tag_strings, meal_strings) is written as it appears in the recipe source, in the language of the source. Never replace it with the name of a household list entry, not even when that entry matches
- Split every ingredient line into its parts:
  * "2 cups flour" → name:"flour", amount:2, unit_string:"cups", description:null
  * "1 large diced onion" → name:"onion", amount:1, unit_string:null, description:"large, diced"
  * "Salt to taste" → name:"salt", amount:null, unit_string:null, description:"to taste"
  * "3 tbsp chopped fresh parsley" → name:"parsley", amount:3, unit_string:"tbsp", description:"chopped, fresh"
- description holds preparation methods (diced, chopped, minced), state (fresh, dried) and special notes (to taste, optional)
- steps: all step-by-step instructions, in order
- cuisine_string: the cuisine type (e.g. "Italian", "Mexican", "Asian")
- tag_strings: relevant tags found in the source (e.g. "vegetarian", "gluten-free", "quick")
- meal_strings: meal types found in the source (e.g. "breakfast", "lunch", "dinner", "dessert")
- cooking_time_minutes: total time (prep + cook)
- image_url: images appear in the source as ![alt text](url). Pick the one showing the finished dish of this recipe and copy its url exactly. Ignore logos, ads, author photos and images of other recipes. The page's social preview image is the meta-og:image line of the metadata header; it is often, but not always, the photo of the dish and can be used too. Use null if unsure
- Use [] for missing list fields and null for missing singular fields

Step 2 - matching, which only fills the *_id fields:
- ingredient_id, unit_id and cuisine_id are the index of the matching entry in the ingredients, units and cuisines list; tag_ids and meal_ids are the indexes of the tags and meals entries matching tag_strings and meal_strings
- Matching never changes the extracted text. E.g. for the ingredient line "1 liter étolaj" with the household entries "3: l" (units) and "7: olaj" (ingredients), the result is name:"étolaj", unit_string:"liter", unit_id:3, ingredient_id:7
- Match by meaning, not by spelling: abbreviations, full forms, singular/plural, inflected forms and translations of the same thing match (e.g. "liter" = "l", "evőkanál" = "ek", "tablespoon" = "tbsp", "tojások" = "tojás")
- An entry matches only if it is the same thing or a more general form of it, never a more specific or different variant: "olaj" must not match "chilli olaj" and "liszt" must not match "rizsliszt", but "extra szűz olívaolaj" may match "olívaolaj"
- Use null, or leave the index out of the array, when no entry matches; never pick a merely similar entry"##;
