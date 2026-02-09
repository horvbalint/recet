use std::{fmt::Debug, io::Cursor};

use anyhow::Result;
use blurhash::encode;
use image::{GenericImageView, codecs::jpeg::JpegEncoder, imageops::FilterType};
use surrealdb_types::{Bytes, SurrealValue};
use surrealism::surrealism;

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
        bytes: Bytes::from(jpeg_bytes),
        blurhash,
    })
}
