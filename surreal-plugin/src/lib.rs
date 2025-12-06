use std::{fmt::Debug, io::Cursor};

use anyhow::Result;
use blurhash::encode;
use image::{GenericImageView, codecs::jpeg::JpegEncoder, imageops::FilterType};
use serde::Deserialize;
use surrealdb_types::{Bytes, SurrealValue, Value, object, vars};
use surrealism::{imports::sql_with_vars, sql, surrealism};

#[derive(Debug, SurrealValue)]
struct ImageData {
    bytes: Bytes,
    blurhash: String,
}

#[surrealism]
fn process_image(buffer: Bytes) -> Result<ImageData> {
    let image = image::load_from_memory(&buffer)?.resize(600, 600, FilterType::Lanczos3);

    let (width, height) = image.dimensions();
    let blurhash = encode(4, 4, width, height, &image.to_rgba8().to_vec())?;

    let mut jpeg_bytes = Vec::new();
    let mut cursor = Cursor::new(&mut jpeg_bytes);
    image.write_with_encoder(JpegEncoder::new_with_quality(&mut cursor, 80))?;

    Ok(ImageData {
        bytes: Bytes::new(jpeg_bytes),
        blurhash,
    })
}

#[derive(Debug, SurrealValue, Deserialize)]
struct Ingredient {
    name: String,
    quantity: Option<f32>,
    unit_string: Option<String>,
    description: Option<String>,
    ingredient: Option<Value>,
    unit: Option<Value>,
}

#[derive(Debug, SurrealValue, Deserialize)]
struct RecipeInfo {
    name: Option<String>,
    portions: Option<String>,
    ingredients: Vec<Ingredient>,
    steps: Vec<String>,
    cuisines: Vec<String>,
    cooking_time_minutes: Option<i32>,
    tags: Vec<String>,
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

#[surrealism]
fn scrape_for_recipe(url: String) -> Result<RecipeInfo> {
    let html: String = sql_with_vars(
        "http::get($url)",
        vars! {
            url: url
        },
    )?;
    let open_ai_url: String = sql("$openAiUrl")?;
    let open_ai_token: String = sql("$openAiToken")?;

    let text = html2text::from_read(html.as_bytes(), usize::MAX)?;

    let response: AiResult = sql_with_vars(
        "http::post($open_ai_url, $body, {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + $open_ai_token,
        })",
        vars! {
            body: object! {
                model: "deepseek-chat",
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
            open_ai_url: open_ai_url,
            open_ai_token: open_ai_token
        },
    )?;

    let mut info: RecipeInfo = serde_json::de::from_str(&response.choices[0].message.content)?;

    for info in &mut info.ingredients {
        info.ingredient = sql_with_vars(
            "SELECT VALUE id FROM ONLY ingredient WHERE name @@ $name LIMIT 1",
            vars! {
                name: info.name.clone()
            },
        )?;

        if let Some(unit_string) = &info.unit_string {
            info.unit = sql_with_vars(
                "SELECT VALUE id FROM ONLY unit WHERE name @@ $name LIMIT 1",
                vars! {
                    name: unit_string.clone()
                },
            )?;
        }
    }

    Ok(info)
}

const SYSTEM_PROMPT: &str = r#"You are a recipe data extraction assistant. Extract recipe information from HTML content and return ONLY a raw JSON object.

The JSON must match this exact schema:
{
  "name": string or null,
  "portions": string or null,
  "ingredients": [
    {
      "name": string,
      "quantity": number or null,
      "unit_string": string or null,
      "description": string or null
    }
  ],
  "steps": [string],
  "cuisines": [string],
  "cooking_time_minutes": integer or null,
  "tags": [string],
  "image_url": string or null
}

Guidelines:
- For ingredients, separate into components:
  * "2 cups flour" → name:"flour", quantity:"2", unit:"cups", description:null
  * "1 large diced onion" → name:"onion", quantity:"1", unit:null, description:"large, diced"
  * "Salt to taste" → name:"salt", quantity:null, unit:null, description:"to taste"
  * "3 tbsp chopped fresh parsley" → name:"parsley", quantity:"3", unit:"tbsp", description:"chopped, fresh"
- Use description field for preparation methods (diced, chopped, minced), state (fresh, dried), and special notes (to taste, optional)
- Extract all step-by-step instructions in order
- Identify cuisine types (e.g., "Italian", "Mexican", "Asian")
- Tags should include dietary info (vegetarian, vegan, gluten-free), meal types (breakfast, dessert), and cooking methods (baking, grilling)
- cooking_time_minutes should be total time (prep + cook)
- Return empty arrays [] for missing list fields, null for missing singular fields"#;
