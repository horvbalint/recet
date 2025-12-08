use std::fmt::Debug;

use anyhow::Result;
use serde::Deserialize;
use surrealdb_types::{RecordId, SurrealValue, object, vars};
use surrealism::{imports::sql_with_vars, sql, surrealism};

#[surrealism]
fn scrape_for_recipe(url: String) -> Result<RecipeInfo> {
    let html: String = sql_with_vars(
        "http::get($url)",
        vars! {
            url: url
        },
    )?;
    let text = html2text::from_read(html.as_bytes(), usize::MAX)?;

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
                    object! { role: "system", content: SYSTEM_PROMPT },
                    object! { role: "user", content: text },
                ],
                stream: false,
                response_format: object!{
                    type: "json_object"
                },
            },
            system_prompt: SYSTEM_PROMPT,
        },
    )?;

    let mut info: RecipeInfo = serde_json::de::from_str(&response.choices[0].message.content)?;

    for info in &mut info.ingredients {
        info.ingredient = find_by_name("ingredient", info.name.clone())?;

        if let Some(unit_string) = &info.unit_string {
            info.unit = find_by_name("unit", unit_string.clone())?;
        }
    }

    if let Some(cuisine_string) = &info.cuisine_string {
        info.cuisine = find_by_name("cuisine", cuisine_string.clone())?;
    }

    for tag_string in &info.tag_strings {
        if let Some(tag) = find_by_name("recipe_tag", tag_string.clone())? {
            info.tags.push(tag);
        }
    }

    for meal_string in &info.meal_strings {
        if let Some(meal) = find_by_name("meal", meal_string.clone())? {
            info.meals.push(meal);
        }
    }

    Ok(info)
}

fn find_by_name(table: &str, name: String) -> Result<Option<RecordId>> {
    let result: Option<RecordId> = sql_with_vars(
        format!("SELECT VALUE id FROM ONLY {table} WHERE name @@ $name LIMIT 1"),
        vars! {
            name: name
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
- cooking_time_minutes should be total time (prep + cook)
- Return empty arrays [] for missing list fields, null for missing singular fields"#;
