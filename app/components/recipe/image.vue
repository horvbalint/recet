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
    public?: boolean
  }
  widthPx: number
  heightPx: number
}>()

const { data: imageUrl, refresh, error } = useAsyncData(`recipe-image-${props.recipe.id.id}`, () => {
  return getRecipeImageUrl(props.recipe.id)
}, {
  immediate: false,
})
logOnError(error)

const imageWrapper = useTemplateRef('image-wrapper')
onMounted(() => {
  if (!props.recipe.image_blur_hash)
    return

  const observer = new IntersectionObserver(
    ([entry]) => {
      if (entry!.isIntersecting) {
        refresh()
        observer.unobserve(entry!.target)
      }
    },
    { rootMargin: '100px' },
  )

  observer.observe(imageWrapper.value!)
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

const viewTransitions = getRecipeViewTransitionNames(props.recipe.id.id)
</script>

<template>
  <div ref="image-wrapper" class="recipe-image">
    <template v-if="recipe.image_blur_hash">
      <canvas v-if="!imageUrl" ref="canvas" :width="props.widthPx" :height="props.heightPx" />
      <img v-else :src="imageUrl!" alt="Recipe Image">
    </template>

    <div v-else class="image-placeholder">
      <icon name="material-symbols:restaurant-rounded" />
    </div>

    <div class="info-badges">
      <cuisine-badge v-if="recipe.cuisine" :cuisine="recipe.cuisine" />

      <neb-tooltip v-if="recipe.public" title="Public recipe" text="This recipe is public and can be viewed by anyone with its public link.">
        <neb-button type="secondary-neutral" small @click.stop="copyPublicUrl(recipe.id.id)">
          <icon name="material-symbols:public" />
        </neb-button>
      </neb-tooltip>
    </div>

    <slot />
  </div>
</template>

<style scoped>
.recipe-image {
  position: relative;
  height: v-bind(heightString);
  view-transition-name: v-bind('viewTransitions.image');

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

.info-badges {
  position: absolute;
  top: var(--space-4);
  right: var(--space-4);
  display: flex;
  gap: var(--space-1);
  /* flex-direction: column;
  gap: var(--space-1);
  align-items: flex-end; */

  .icon {
    font-size: 20px !important;
    margin: -4px;
  }
}

.dark-mode {
  .image-placeholder {
    background: linear-gradient(135deg, var(--neutral-color-800), var(--neutral-color-900));
  }
}
</style>
