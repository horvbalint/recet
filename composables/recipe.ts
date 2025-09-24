import type { RecordId } from 'surrealdb'
import { encode as encodeBlurhash } from 'blurhash'
import { readAndCompressImage } from 'browser-image-resizer'

export async function getRecipeImageUrl(recipeId: RecordId<'recipe'>) {
  const [buffer] = await db.query<[ArrayBuffer | null]>(surql`
    SELECT VALUE image FROM ONLY type::thing('recipe', ${recipeId})
  `)

  if (!buffer)
    return null
  else
    return URL.createObjectURL(new Blob([buffer], { type: 'image/*' }))
}

export async function processRecipeImage(file: File | null) {
  if (!file)
    return { blurhash: null, imageBuffer: null }

  const resizedImage = await readAndCompressImage(file, {
    quality: 0.8,
    maxHeight: 800,
    maxWidth: 800,
  })

  const image = await loadImage(resizedImage)

  const { naturalWidth: width, naturalHeight: height } = image
  const canvas = new OffscreenCanvas(width, height)
  const ctx = canvas.getContext('2d')!
  ctx.drawImage(image, 0, 0)
  const imageData = ctx.getImageData(0, 0, width, height)

  const blurhash = encodeBlurhash(imageData.data, width, height, 4, 4)
  const imageBuffer = await resizedImage.arrayBuffer()

  return { blurhash, imageBuffer }
}

function loadImage(blob: Blob): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const image = new Image()
    image.src = URL.createObjectURL(blob)

    image.onload = () => resolve(image)
    image.onerror = reject
  })
}
