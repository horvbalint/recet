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

    if !info.ingredients.is_empty()
        && match_ingredients_with_ai(&household, &mut info.ingredients).is_err()
    {
        for info in &mut info.ingredients {
            info.ingredient = find_by_name(&household, "ingredient", info.name.clone())?;

            if let Some(unit_string) = &info.unit_string {
                info.unit = find_by_name(&household, "unit", unit_string.clone())?;
            }
        }
    }

    if let Some(cuisine_string) = &info.cuisine_string {
        info.cuisine = find_by_name(&household, "cuisine", cuisine_string.clone())?;
    }

    for tag_string in &info.tag_strings {
        if let Some(tag) = find_by_name(&household, "recipe_tag", tag_string.clone())? {
            info.tags.push(tag);
        }
    }

    for meal_string in &info.meal_strings {
        if let Some(meal) = find_by_name(&household, "meal", meal_string.clone())? {
            info.meals.push(meal);
        }
    }

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

fn match_ingredients_with_ai(household: &RecordId, ingredients: &mut [Ingredient]) -> Result<()> {
    let known_ingredients = list_names(household, "ingredient")?;
    let known_units = list_names(household, "unit")?;

    if known_ingredients.is_empty() && known_units.is_empty() {
        return Ok(());
    }

    let request = serde_json::json!({
        "recipe_ingredients": ingredients
            .iter()
            .enumerate()
            .map(|(index, ing)| serde_json::json!({
                "index": index,
                "name": ing.name,
                "unit": ing.unit_string,
                "description": ing.description,
            }))
            .collect::<Vec<_>>(),
        "known_ingredients": known_ingredients
            .iter()
            .enumerate()
            .map(|(index, record)| serde_json::json!({ "id": index, "name": record.name }))
            .collect::<Vec<_>>(),
        "known_units": known_units
            .iter()
            .enumerate()
            .map(|(index, record)| serde_json::json!({ "id": index, "name": record.name }))
            .collect::<Vec<_>>(),
    });

    let result: MatchResult =
        serde_json::de::from_str(&chat_completion(MATCH_PROMPT, request.to_string())?)?;

    for matched in result.matches {
        let Some(ing) = ingredients.get_mut(matched.index) else {
            continue;
        };

        ing.ingredient = matched
            .ingredient_id
            .and_then(|id| known_ingredients.get(id))
            .map(|record| record.id.clone());

        ing.unit = matched
            .unit_id
            .and_then(|id| known_units.get(id))
            .map(|record| record.id.clone());
    }

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

fn find_by_name(household: &RecordId, table: &str, name: String) -> Result<Option<RecordId>> {
    let result: Option<RecordId> = sql_with_vars(
        format!(
            "SELECT VALUE id FROM ONLY {table} WHERE name @@ $name && household = $household LIMIT 1"
        ),
        vars! {
            name: name,
            household: household.clone()
        },
    )?;

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
}

#[derive(Debug, SurrealValue)]
struct NamedRecord {
    id: RecordId,
    name: String,
}

#[derive(Debug, Deserialize)]
struct MatchResult {
    #[serde(default)]
    matches: Vec<IngredientMatch>,
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

const MATCH_PROMPT: &str = r#"You match ingredients extracted from a recipe to the ingredients and units already saved in a household's database. Return ONLY a raw JSON object.

The input is a JSON object with:
- "recipe_ingredients": the ingredients of the recipe, each with an "index", a "name", a "unit" and a "description"
- "known_ingredients": the household's saved ingredients, each with an "id" and a "name"
- "known_units": the household's saved units, each with an "id" and a "name"

The output must match this exact schema, with one entry for every recipe ingredient:
{
  "matches": [
    {
      "index": integer,
      "ingredient_id": integer or null,
      "unit_id": integer or null
    }
  ]
}

Guidelines:
- "index" is the index of the recipe ingredient, "ingredient_id" and "unit_id" are ids from "known_ingredients" and "known_units"
- The recipe and the saved names may be in different languages, use singular or plural forms, abbreviations or synonyms: match by meaning, not spelling
  * "tbsp", "tablespoon", "evőkanál" are the same unit; "g", "gram", "gramm" are the same unit
  * "eggs" matches "egg", "tojás" matches "egg"
- An ingredient only matches a saved ingredient that is the same food. Preparation and state ("chopped", "fresh", "large") do not matter, so "fresh parsley" matches "parsley", but "garlic powder" does not match "garlic"
- Use null when there is no good match, never guess an unrelated item
- unit_id is null when the recipe ingredient has no unit
- Only use ids that appear in the input"#;
