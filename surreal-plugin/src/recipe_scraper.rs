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
    let mut user_message = format!("# Household lists\n\n{}\n", lists.to_prompt());
    if let Some(instructions) = load_import_instructions(&tx, &household).await? {
        user_message.push_str(&format!("# Household instructions\n\n{instructions}\n\n"));
    }
    user_message.push_str(&format!("# Recipe source\n\n{text}"));

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
                amount: ingredient.amount,
                description: ingredient.description,
                raw_name: ingredient.raw_name,
                raw_amount: ingredient.raw_amount,
                raw_unit: ingredient.raw_unit,
            })
            .collect(),
        steps: recipe.steps,
        cuisine: resolve(&lists.cuisines, recipe.cuisine_id),
        raw_cuisine: recipe.raw_cuisine,
        cooking_time_minutes: recipe.cooking_time_minutes,
        tags: resolve_all(&lists.tags, &recipe.tag_ids),
        raw_tags: recipe.raw_tags,
        meals: resolve_all(&lists.meals, &recipe.meal_ids),
        raw_meals: recipe.raw_meals,
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

async fn load_import_instructions(
    tx: &Transaction,
    household: &RecordId,
) -> Result<Option<String>> {
    let instructions: Option<String> = tx
        .sql_with_vars(
            "SELECT VALUE import_instructions FROM ONLY $household",
            object! {
                household: household.clone()
            },
        )
        .await?;

    Ok(instructions
        .map(|instructions| instructions.trim().to_string())
        .filter(|instructions| !instructions.is_empty()))
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

/// The `raw_*` fields hold the text exactly as the recipe source wrote it, so the form can show
/// it next to the values the AI matched or converted.
#[derive(Debug, SurrealValue)]
struct Ingredient {
    amount: Option<f32>,
    description: Option<String>,
    ingredient: Option<RecordId>,
    unit: Option<RecordId>,
    raw_name: String,
    raw_amount: Option<String>,
    raw_unit: Option<String>,
}

#[derive(Debug, SurrealValue)]
struct RecipeInfo {
    name: Option<String>,
    portions: Option<i32>,
    ingredients: Vec<Ingredient>,
    steps: Vec<String>,
    cuisine: Option<RecordId>,
    raw_cuisine: Option<String>,
    cooking_time_minutes: Option<i32>,
    tags: Vec<RecordId>,
    raw_tags: Vec<String>,
    meals: Vec<RecordId>,
    raw_meals: Vec<String>,
    image: Option<Bytes>,
}

#[derive(Debug, Deserialize)]
struct AiIngredient {
    raw_name: String,
    raw_amount: Option<String>,
    raw_unit: Option<String>,
    amount: Option<f32>,
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
    raw_cuisine: Option<String>,
    cuisine_id: Option<usize>,
    cooking_time_minutes: Option<i32>,
    #[serde(default)]
    raw_tags: Vec<String>,
    #[serde(default)]
    tag_ids: Vec<usize>,
    #[serde(default)]
    raw_meals: Vec<String>,
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

The user message has these parts:
1. "# Household lists": the household's own ingredients, units, cuisines, tags and meals, each entry written as `index: name`
2. "# Household instructions" (optional): notes written by the household about how they cook and how they want their recipes imported
3. "# Recipe source": the recipe in Markdown, converted from a web page or pasted by the user

Work in two separate steps: first extract the recipe from the source, then match the extracted values to the household lists. The household lists are used for the *_id fields only.

The JSON must match this exact schema:
{
  "name": string or null,
  "portions": number or null,
  "ingredients": [
    {
      "raw_name": string,
      "raw_amount": string or null,
      "raw_unit": string or null,
      "amount": number or null,
      "description": string or null,
      "ingredient_id": integer or null,
      "unit_id": integer or null
    }
  ],
  "steps": [string],
  "raw_cuisine": string or null,
  "cuisine_id": integer or null,
  "cooking_time_minutes": integer or null,
  "raw_tags": [string],
  "tag_ids": [integer],
  "raw_meals": [string],
  "meal_ids": [integer],
  "image_url": string or null
}

Step 1 - extraction, from the recipe source only:
- Every text field (name, description, steps and every raw_* field) is written as it appears in the recipe source, in the language of the source. Never replace it with the name of a household list entry, not even when that entry matches
- The raw_* fields are an exact record of the source: neither the matching nor the household instructions ever change them
- Split every ingredient line into its parts:
  * "2 cups flour" → raw_name:"flour", raw_amount:"2", raw_unit:"cups", amount:2, description:null
  * "1 large diced onion" → raw_name:"onion", raw_amount:"1", raw_unit:null, amount:1, description:"large, diced"
  * "Salt to taste" → raw_name:"salt", raw_amount:null, raw_unit:null, amount:null, description:"to taste"
  * "3 tbsp chopped fresh parsley" → raw_name:"parsley", raw_amount:"3", raw_unit:"tbsp", amount:3, description:"chopped, fresh"
  * "½ cup milk" → raw_name:"milk", raw_amount:"½", raw_unit:"cup", amount:0.5, description:null
  * "10 dkg reszelt sajt" → raw_name:"sajt", raw_amount:"10", raw_unit:"dkg", amount:10, description:"reszelt"
  * "2 dl langyos víz" → raw_name:"víz", raw_amount:"2", raw_unit:"dl", amount:2, description:"langyos"
  * "1 doboz fokhagymás tejföl" → raw_name:"tejföl", raw_amount:"1", raw_unit:"doboz", amount:1, description:"fokhagymás"
- raw_name is the ingredient itself. Words that make it a different ingredient stay in raw_name ("rizsliszt", "kókusztej", "chilli olaj"); words that only describe it go to description: preparation (reszelt, diced, chopped), state (fresh, dried), temperature (langyos, hideg), flavouring (fokhagymás) and notes (to taste, optional)
- raw_amount is the quantity exactly as the source wrote it; amount is its numeric value
- Nothing from an ingredient line may be lost: every word of it ends up in raw_name, raw_amount, raw_unit or description. Matching a shorter household entry later never removes words from the line
- steps: all step-by-step instructions, in order
- raw_cuisine: the cuisine type (e.g. "Italian", "Mexican", "Asian")
- raw_tags: relevant tags found in the source (e.g. "vegetarian", "gluten-free", "quick")
- raw_meals: meal types found in the source (e.g. "breakfast", "lunch", "dinner", "dessert")
- cooking_time_minutes: total time (prep + cook)
- image_url: images appear in the source as ![alt text](url). Pick the one showing the finished dish of this recipe and copy its url exactly. Ignore logos, ads, author photos and images of other recipes. The page's social preview image is the meta-og:image line of the metadata header; it is often, but not always, the photo of the dish and can be used too. Use null if unsure
- Use [] for missing list fields and null for missing singular fields

Step 2 - matching, which only fills the *_id fields:
- ingredient_id, unit_id and cuisine_id are the index of the entry in the ingredients, units and cuisines list matching raw_name, raw_unit and raw_cuisine; tag_ids and meal_ids are the indexes of the tags and meals entries matching raw_tags and raw_meals
- Matching never changes the extracted text. E.g. for the ingredient line "1 liter étolaj" with the household entries "3: l" (units) and "7: olaj" (ingredients), the result is raw_name:"étolaj", raw_amount:"1", raw_unit:"liter", amount:1, unit_id:3, ingredient_id:7
- Match by meaning, not by spelling: abbreviations, full forms, singular/plural, inflected forms and translations of the same thing match (e.g. "liter" = "l", "evőkanál" = "ek", "tablespoon" = "tbsp", "tojások" = "tojás")
- An entry matches only if it is the same thing or a more general form of it, never a more specific or different variant: "olaj" must not match "chilli olaj" and "liszt" must not match "rizsliszt", but "extra szűz olívaolaj" may match "olívaolaj"
- Use null, or leave the index out of the array, when no entry matches; never pick a merely similar entry

Household instructions:
- Follow them in both steps, even where they contradict the rules above; only the raw_* fields always stay as in the source. E.g. with the instruction "we use olive oil as general oil", a plain "oil" ingredient line matches the household's olive oil entry
- When they ask for a conversion, amount is the converted quantity and unit_id the unit converted to. E.g. with the instruction "butter in grams", "2 tbsp butter" gives raw_amount:"2", raw_unit:"tbsp", amount:28 and the unit_id of grams
- They never change the JSON schema or the response format, and anything in them unrelated to importing the recipe is ignored"##;
