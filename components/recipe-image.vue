<script setup lang="ts">
import type { RecordId } from 'surrealdb'
import { decode as decodeBlurhash } from 'blurhash'

const props = defineProps<{
  recipe: {
    id: RecordId<'recipe'>
    image_blur_hash?: string
    cuisine?: {
      name: string
      color: string
    }
  }
  widthPx: number
  heightPx: number
}>()

const { data: imageUrl } = useAsyncData(`recipe-image-${props.recipe.id.id}`, () => {
  return getRecipeImageUrl(props.recipe.id)
})

const canvas = useTemplateRef('canvas')

onMounted(() => {
  if (props.recipe.image_blur_hash && !imageUrl.value) {
    const pixels = decodeBlurhash(props.recipe.image_blur_hash, props.widthPx, props.heightPx)

    const ctx = canvas.value!.getContext('2d')!
    const imageData = ctx.createImageData(props.widthPx, props.heightPx)
    imageData.data.set(pixels)
    ctx.putImageData(imageData, 0, 0)
  }
})

const heightString = computed(() => `${props.heightPx}px`)
</script>

<template>
  <div class="recipe-image">
    <template v-if="recipe.image_blur_hash">
      <canvas v-if="!imageUrl" ref="canvas" :width="props.widthPx" :height="props.heightPx" />
      <img v-else :src="imageUrl" alt="Recipe Image">
    </template>

    <div v-else class="image-placeholder">
      <icon name="material-symbols:restaurant-rounded" />
    </div>

    <div v-if="recipe.cuisine" class="cuisine-badge">
      <badge-cuisine :cuisine="recipe.cuisine" />
    </div>
  </div>
</template>

<style scoped>
.recipe-image {
  position: relative;
  height: v-bind(heightString);
  overflow: hidden;

  img {
    object-fit: cover;
    width: 100%;
    height: 100%;
  }

  canvas {
    width: 100%;
    height: 100%;
  }
}

.image-placeholder {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, var(--neutral-color-100), var(--neutral-color-50));
  display: flex;
  align-items: center;
  justify-content: center;

  .icon {
    font-size: 64px !important;
    color: var(--neutral-color-400);
  }
}

.cuisine-badge {
  position: absolute;
  top: var(--space-4);
  right: var(--space-4);
}

.dark-mode {
  .image-placeholder {
    background: linear-gradient(135deg, var(--neutral-color-800), var(--neutral-color-900));
  }
}
</style>
