use std::fmt::Debug;

use anyhow::Result;
use serde::Deserialize;
use surrealdb_types::{RecordId, SurrealValue, object, vars};
use surrealism::{imports::sql_with_vars, sql, surrealism};

#[surrealism]
fn scrape_for_recipe(
    household: RecordId,
    source_type: String,
    source_text: String,
) -> Result<RecipeInfo> {
    let text = if source_type == "text" {
        source_text
    } else if source_type == "url" {
        let html: String = sql_with_vars(
            "http::get($url)",
            vars! {
                url: source_text
            },
        )?;
        html2text::from_read(html.as_bytes(), usize::MAX)?
    } else {
        return Err(anyhow::anyhow!("Invalid source type"));
    };

    let mut info: RecipeInfo = serde_json::de::from_str(&chat_completion(SYSTEM_PROMPT, text)?)?;
    match_records_with_ai(&household, &mut info)?;

    Ok(info)
}

fn chat_completion(system_prompt: &str, user_prompt: String) -> Result<String> {
    let ai_model: String = sql("$openAiModel")?;

    let response: AiResult = sql_with_vars(
        "http::post($openAiBaseUrl + '/v1/chat/completions', $body, {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + $openAiToken,
        })",
        vars! {
            body: object! {
                model: ai_model,
                messages: vec![
                    object! { role: "system", content: system_prompt },
                    object! { role: "user", content: user_prompt },
                ],
                stream: false,
                response_format: object!{
                    type: "json_object"
                },
            },
        },
    )?;

    let choice = response
        .choices
        .into_iter()
        .next()
        .ok_or_else(|| anyhow::anyhow!("AI returned no choices"))?;

    Ok(choice.message.content)
}

fn match_records_with_ai(household: &RecordId, info: &mut RecipeInfo) -> Result<()> {
    let known_ingredients = list_names(household, "ingredient")?;
    let known_units = list_names(household, "unit")?;
    let known_cuisines = list_names(household, "cuisine")?;
    let known_tags = list_names(household, "recipe_tag")?;
    let known_meals = list_names(household, "meal")?;

    let request = serde_json::json!({
        "recipe": {
            "ingredients": info
                .ingredients
                .iter()
                .enumerate()
                .map(|(index, ing)| serde_json::json!({
                    "index": index,
                    "name": ing.name,
                    "unit": ing.unit_string,
                    "description": ing.description,
                }))
                .collect::<Vec<_>>(),
            "cuisine": info.cuisine_string,
            "tags": info.tag_strings,
            "meals": info.meal_strings,
        },
        "known": {
            "ingredients": to_prompt_list(&known_ingredients),
            "units": to_prompt_list(&known_units),
            "cuisines": to_prompt_list(&known_cuisines),
            "tags": to_prompt_list(&known_tags),
            "meals": to_prompt_list(&known_meals),
        },
    });

    let result: MatchResult =
        serde_json::de::from_str(&chat_completion(MATCH_PROMPT, request.to_string())?)?;

    for matched in result.ingredients {
        let Some(ing) = info.ingredients.get_mut(matched.index) else {
            continue;
        };

        ing.ingredient = resolve(&known_ingredients, matched.ingredient_id);
        ing.unit = resolve(&known_units, matched.unit_id);
    }

    info.cuisine = resolve(&known_cuisines, result.cuisine_id);
    info.tags = resolve_all(&known_tags, result.tag_ids);
    info.meals = resolve_all(&known_meals, result.meal_ids);

    Ok(())
}

fn list_names(household: &RecordId, table: &str) -> Result<Vec<NamedRecord>> {
    let result: Vec<NamedRecord> = sql_with_vars(
        format!("SELECT id, name FROM {table} WHERE household = $household"),
        vars! {
            household: household.clone()
        },
    )?;

    Ok(result)
}

fn to_prompt_list(records: &[NamedRecord]) -> Vec<serde_json::Value> {
    records
        .iter()
        .enumerate()
        .map(|(index, record)| serde_json::json!({ "id": index, "name": record.name }))
        .collect()
}

fn resolve(records: &[NamedRecord], index: Option<usize>) -> Option<RecordId> {
    index
        .and_then(|index| records.get(index))
        .map(|record| record.id.clone())
}

fn resolve_all(records: &[NamedRecord], indexes: Vec<usize>) -> Vec<RecordId> {
    let mut ids: Vec<RecordId> = Vec::new();

    for id in indexes
        .into_iter()
        .filter_map(|index| resolve(records, Some(index)))
    {
        if !ids.contains(&id) {
            ids.push(id);
        }
    }

    ids
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
}

#[derive(Debug, SurrealValue)]
struct NamedRecord {
    id: RecordId,
    name: String,
}

#[derive(Debug, Deserialize)]
struct MatchResult {
    #[serde(default)]
    ingredients: Vec<IngredientMatch>,
    cuisine_id: Option<usize>,
    #[serde(default)]
    tag_ids: Vec<usize>,
    #[serde(default)]
    meal_ids: Vec<usize>,
}

#[derive(Debug, Deserialize)]
struct IngredientMatch {
    index: usize,
    ingredient_id: Option<usize>,
    unit_id: Option<usize>,
}

#[derive(Debug, SurrealValue)]
struct AiResult {
    choices: Vec<AiChoice>,
}

#[derive(Debug, SurrealValue)]
struct AiChoice {
    message: AiMessage,
}

#[derive(Debug, SurrealValue)]
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
- cooking_time_minutes should be total time (prep + cook)
- Return empty arrays [] for missing list fields, null for missing singular fields"#;

const MATCH_PROMPT: &str = r#"You match data extracted from a recipe to the records already saved in a household's database. Return ONLY a raw JSON object.

The input is a JSON object with:
- "recipe": what was extracted from the recipe
  * "ingredients": each with an "index", a "name", a "unit" and a "description"
  * "cuisine": string or null
  * "tags": [string]
  * "meals": [string]
- "known": the household's saved records, each list item having an "id" and a "name"
  * "ingredients", "units", "cuisines", "tags", "meals"

The output must match this exact schema:
{
  "ingredients": [
    {
      "index": integer,
      "ingredient_id": integer or null,
      "unit_id": integer or null
    }
  ],
  "cuisine_id": integer or null,
  "tag_ids": [integer],
  "meal_ids": [integer]
}

Guidelines:
- Return one entry in "ingredients" for every recipe ingredient, "index" being the index of the recipe ingredient
- Every id must be an id from the matching "known" list: ingredient_id from "known.ingredients", unit_id from "known.units", cuisine_id from "known.cuisines", tag_ids from "known.tags", meal_ids from "known.meals"
- The recipe and the saved names may be in different languages, use singular or plural forms, abbreviations or synonyms: match by meaning, not spelling
  * "tbsp", "tablespoon", "evőkanál" are the same unit; "g", "gram", "gramm" are the same unit
  * "eggs" matches "egg", "tojás" matches "egg"; "vacsora" matches "dinner"
- An ingredient only matches a saved ingredient that is the same food. Preparation and state ("chopped", "fresh", "large") do not matter, so "fresh parsley" matches "parsley", but "garlic powder" does not match "garlic"
- unit_id is null when the recipe ingredient has no unit
- Only include tags and meals that correspond to one of the recipe's "tags" and "meals"
- Use null or leave the item out when there is no good match, never guess an unrelated record"#;
