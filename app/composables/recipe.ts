import type { RecordId } from 'surrealdb'
import type { Recipe } from '~/pages/index.vue'
import { encode as encodeBlurhash } from 'blurhash'
import { readAndCompressImage } from 'browser-image-resizer'

const cachedRecipe = ref<Recipe | null>(null)
export function setCachedRecipe(recipe: Recipe) {
  cachedRecipe.value = recipe
}
export function getCachedRecipe(recipeId: RecordId<'recipe'>['id']) {
  if (recipeId !== cachedRecipe.value?.id.id)
    return null

  return cachedRecipe.value
}

export function getRecipeViewTransitionNames(recipeId: RecordId<'recipe'>['id']) {
  return computed(() => {
    if (recipeId !== cachedRecipe.value?.id.id)
      return {}

    return {
      // container: 'recipe-container',
      // name: 'recipe-name',
      // meta: 'recipe-meta',
      // tags: 'recipe-tags',
      // mealTypes: 'recipe-meal-types',
      image: 'recipe-image',
      // cuisine: 'recipe-cuisine',
    }
  })
}

const cachedRecipeImages = new Map<RecordId<'recipe'>['id'], string | null>()
export async function getRecipeImageUrl(recipeId: RecordId<'recipe'>) {
  if (cachedRecipeImages.has(recipeId.id))
    return cachedRecipeImages.get(recipeId.id)!

  const [buffer] = await db.query<[ArrayBuffer | null]>(surql`
    SELECT VALUE image FROM ONLY type::thing('recipe', ${recipeId})
  `)

  const url = buffer ? URL.createObjectURL(new Blob([buffer], { type: 'image/*' })) : null
  cachedRecipeImages.set(recipeId.id, url)
  return url
}

export async function processRecipeImage(file: File | null) {
  if (!file)
    return { blurhash: undefined, imageBuffer: undefined }

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
