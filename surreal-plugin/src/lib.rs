use std::io::Cursor;

use fast_blurhash::compute_dct_iter;
use image::{codecs::jpeg::JpegEncoder, imageops::FilterType};
use surrealdb_types::{Bytes, SurrealValue};
use surrealism::surrealism;

#[derive(Debug, SurrealValue)]
struct ImageData {
    bytes: Bytes,
    blurhash: String,
}

#[surrealism]
fn process_image(buffer: Bytes) -> ImageData {
    let image = image::load_from_memory(&buffer)
        .unwrap()
        .resize(600, 600, FilterType::Lanczos3);

    let tiny = image.thumbnail(32, 32).to_rgb8().to_vec();
    let rgb_pixels = tiny
        .chunks_exact(3)
        .map(|chunk| [chunk[0], chunk[1], chunk[2]]);

    let blurhash = compute_dct_iter(rgb_pixels, 32, 32, 4, 4).into_blurhash();

    let mut jpeg_bytes = Vec::new();
    let mut cursor = Cursor::new(&mut jpeg_bytes);
    image
        .write_with_encoder(JpegEncoder::new_with_quality(&mut cursor, 80))
        .unwrap();

    ImageData {
        bytes: Bytes::new(jpeg_bytes),
        blurhash,
    }
}
