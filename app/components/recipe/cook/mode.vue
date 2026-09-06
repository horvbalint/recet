<script setup lang="ts">
import type { CookIngredient, CookSubRecipe } from './ingredients.vue'

const props = defineProps<{
  name: string
  steps: string[]
  ingredients?: CookIngredient[]
  subRecipes?: CookSubRecipe[]
  portionRatio: number
}>()

const emit = defineEmits<{
  close: []
}>()

const portions = defineModel<number | undefined>('portions')

const slideIndex = ref(0)
const showIngredients = ref(false)
const checkedIngredients = ref<number[]>([])

const hasSteps = computed(() => props.steps.length > 0)
const slideCount = computed(() => props.steps.length + 1)
const isIngredientSlide = computed(() => slideIndex.value === 0)

function goToSlide(index: number) {
  if (!hasSteps.value)
    return

  slideIndex.value = Math.min(Math.max(index, 0), slideCount.value - 1)
}

// SCREEN WAKE LOCK
const { isSupported: isWakeLockSupported, request: requestWakeLock, release: releaseWakeLock } = useWakeLock()

async function keepScreenAwake() {
  if (!isWakeLockSupported.value)
    return

  try {
    await requestWakeLock('screen')
  }
  catch (error) {
    console.error('Could not keep the screen awake:', error)
  }
}

// the OS drops the wake lock every time the page is hidden, so it has to be taken again
useEventListener(document, 'visibilitychange', () => {
  if (document.visibilityState === 'visible')
    keepScreenAwake()
})

onMounted(() => keepScreenAwake())
onBeforeUnmount(() => releaseWakeLock())

// guards against the recipe's steps being edited down to zero while cook mode is open
watch(hasSteps, () => {
  if (!hasSteps.value)
    emit('close')
})

// NAVIGATION
onKeyStroke('ArrowRight', () => goToSlide(slideIndex.value + 1))
onKeyStroke('ArrowLeft', () => goToSlide(slideIndex.value - 1))
onKeyStroke('Escape', () => emit('close'))

const slideArea = useTemplateRef('slide-area')
useSwipe(slideArea, {
  onSwipeEnd: (_event, direction) => {
    if (direction === 'left')
      goToSlide(slideIndex.value + 1)
    else if (direction === 'right')
      goToSlide(slideIndex.value - 1)
  },
})
</script>

<template>
  <neb-pop-up :model-value="true" :close-on-background-click="false">
    <div class="cook-mode">
      <header class="cook-header">
        <neb-button type="tertiary-neutral" small @click="emit('close')">
          <icon name="material-symbols:close-rounded" />
          <span class="hide-on-mobile">{{ $t('recipes.cook.close') }}</span>
        </neb-button>

        <div class="header-title">
          <span class="recipe-name">{{ name }}</span>

          <span class="slide-label">
            {{ isIngredientSlide
              ? $t('recipes.cook.prep')
              : $t('recipes.cook.stepCounter', { current: slideIndex, total: steps.length }) }}
          </span>
        </div>

        <neb-button
          v-if="!isIngredientSlide"
          type="tertiary-neutral"
          small
          :title="showIngredients ? $t('recipes.cook.hideIngredients') : $t('recipes.cook.showIngredients')"
          @click="showIngredients = !showIngredients"
        >
          <icon name="material-symbols:grocery" />
        </neb-button>

        <div v-else class="header-spacer" />
      </header>

      <div class="progress-track">
        <div class="progress-value" :style="{ transform: `scaleX(${hasSteps ? (slideIndex + 1) / slideCount : 0})` }" />
      </div>

      <div class="cook-body">
        <main ref="slide-area" class="slide-area">
          <recipe-cook-ingredients
            v-if="isIngredientSlide"
            v-model:portions="portions"
            v-model:checked="checkedIngredients"
            :ingredients
            :sub-recipes="subRecipes"
            :portion-ratio="portionRatio"
          />

          <p v-else class="cook-step">
            {{ steps[slideIndex - 1] ?? '' }}
          </p>
        </main>

        <aside v-if="showIngredients && !isIngredientSlide" class="ingredient-panel">
          <recipe-cook-ingredients
            v-model:portions="portions"
            v-model:checked="checkedIngredients"
            :ingredients
            :sub-recipes="subRecipes"
            :portion-ratio="portionRatio"
          />
        </aside>
      </div>

      <footer class="cook-footer">
        <neb-button type="secondary-neutral" :disabled="slideIndex === 0" @click="goToSlide(slideIndex - 1)">
          <icon name="material-symbols:arrow-back-rounded" />
          <span class="hide-on-mobile">{{ $t('recipes.cook.previous') }}</span>
        </neb-button>

        <neb-button v-if="slideIndex >= slideCount - 1" @click="emit('close')">
          <icon name="material-symbols:check-rounded" />
          <span>{{ $t('recipes.cook.finish') }}</span>
        </neb-button>

        <neb-button v-else @click="goToSlide(slideIndex + 1)">
          <span class="hide-on-mobile">{{ $t('recipes.cook.next') }}</span>
          <icon name="material-symbols:arrow-forward-rounded" />
        </neb-button>
      </footer>
    </div>
  </neb-pop-up>
</template>

<style scoped>
.cook-mode {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  background: var(--neb-bg-page);
}

.cook-header {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  padding: var(--space-3) var(--space-4);
  border-bottom: 1px solid var(--neb-border-subtle);
}

.header-title {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 0;
}

.header-spacer {
  width: 36px;
}

.recipe-name {
  width: 100%;
  min-width: 0;
  font-weight: 600;
  color: var(--neb-text);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.slide-label {
  font-size: var(--text-sm);
  color: var(--neb-text-subtle);
}

.cook-step {
  font-size: 32px;
  line-height: 1.45;
  color: var(--neb-text);
  white-space: pre-wrap;
}

.progress-track {
  flex-shrink: 0;
  height: 4px;
  background: var(--neb-bg-muted);
}

.progress-value {
  height: 100%;
  transform-origin: left;
  background: var(--neb-bg-primary-solid);
  transition: transform var(--duration-default) ease;
}

.cook-body {
  flex: 1;
  display: flex;
  align-items: stretch;
  min-height: 0;
}

.slide-area {
  flex: 1;
  min-width: 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
  padding: var(--space-12) var(--space-8);
  overflow-y: auto;
}

/* auto margins centre the slide vertically without the clipped overflow that
   align-items: center produces once the content is taller than the area */
.slide-area > * {
  width: 100%;
  max-width: 640px;
  margin: auto;
}

.ingredient-panel {
  width: 340px;
  flex-shrink: 0;
  min-height: 0;
  padding: var(--space-6);
  border-left: 1px solid var(--neb-border-subtle);
  background: var(--neb-bg-raised);
  overflow-y: auto;
}

.cook-footer {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  padding: var(--space-4);
  border-top: 1px solid var(--neb-border-subtle);
}

@media (--tablet-viewport) {
  .cook-body {
    position: relative;
    flex-direction: column;
  }

  .slide-area {
    padding: var(--space-6) var(--space-4);
  }

  .slide-area > * {
    margin-block: 0 auto;
  }

  .slide-area > .cook-step {
    margin-block: auto;
  }

  .ingredient-panel {
    position: absolute;
    inset: 0;
    width: 100%;
    padding: var(--space-4);
    border-left: none;
    border-top: none;
  }

  .hide-on-mobile {
    display: none;
  }

  .cook-step {
    font-size: 24px;
  }
}
</style>
