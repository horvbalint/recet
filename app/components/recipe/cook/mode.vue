<script setup lang="ts">
import type { RecordId } from 'surrealdb'

interface CookIngredient {
  ingredient: string
  amount?: number
  unit?: string
  description?: string
}

interface CookSubRecipe {
  recipe: {
    id: RecordId<'recipe'>
    name: string
  }
  description?: string
}

const props = defineProps<{
  name: string
  steps: string[]
  ingredients?: CookIngredient[]
  subRecipes?: CookSubRecipe[]
  portionRatio: number
}>()

const isOpen = defineModel<boolean>({ required: true })
const portions = defineModel<number | undefined>('portions')

const stepIndex = ref(0)
const showIngredients = ref(!isMobile.value)
const checkedIngredients = ref<number[]>([])

const currentStep = computed(() => props.steps[stepIndex.value] ?? '')

// the recipe page falls back to a cached placeholder with no steps whenever its query has no
// data, so an errored refresh can empty this out while cook mode is open
const hasSteps = computed(() => props.steps.length > 0)
const progress = computed(() => hasSteps.value ? (stepIndex.value + 1) / props.steps.length : 0)

function goToStep(index: number) {
  if (!hasSteps.value)
    return

  stepIndex.value = Math.min(Math.max(index, 0), props.steps.length - 1)
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
  if (isOpen.value && document.visibilityState === 'visible')
    keepScreenAwake()
})

watch(isOpen, (open) => {
  if (open) {
    stepIndex.value = 0
    checkedIngredients.value = []
    showIngredients.value = !isMobile.value

    keepScreenAwake()
  }
  else {
    releaseWakeLock()
  }
})

watch(hasSteps, () => {
  if (isOpen.value && !hasSteps.value)
    isOpen.value = false
})

onBeforeUnmount(() => releaseWakeLock())

// NAVIGATION
onKeyStroke('ArrowRight', () => {
  if (isOpen.value)
    goToStep(stepIndex.value + 1)
})

onKeyStroke('ArrowLeft', () => {
  if (isOpen.value)
    goToStep(stepIndex.value - 1)
})

onKeyStroke('Escape', () => {
  if (isOpen.value)
    isOpen.value = false
})

const stepArea = useTemplateRef('step-area')
useSwipe(stepArea, {
  onSwipeEnd: (_event, direction) => {
    if (direction === 'left')
      goToStep(stepIndex.value + 1)
    else if (direction === 'right')
      goToStep(stepIndex.value - 1)
  },
})

function decrementPortions() {
  if (portions.value && portions.value >= 2)
    portions.value -= 1
}

function incrementPortions() {
  if (portions.value)
    portions.value += 1
}
</script>

<template>
  <neb-pop-up v-model="isOpen" :close-on-background-click="false">
    <div class="cook-mode">
      <header class="cook-header">
        <neb-button type="tertiary-neutral" small @click="isOpen = false">
          <icon name="material-symbols:close-rounded" />
          <span class="hide-on-mobile">{{ $t('recipes.cook.close') }}</span>
        </neb-button>

        <div class="header-title">
          <span class="recipe-name">{{ name }}</span>
          <span class="step-counter">{{ $t('recipes.cook.stepCounter', { current: stepIndex + 1, total: steps.length }) }}</span>
        </div>

        <neb-button
          type="tertiary-neutral"
          small
          :title="showIngredients ? $t('recipes.cook.hideIngredients') : $t('recipes.cook.showIngredients')"
          @click="showIngredients = !showIngredients"
        >
          <icon name="material-symbols:grocery" />
        </neb-button>
      </header>

      <div class="progress-track">
        <div class="progress-value" :style="{ transform: `scaleX(${progress})` }" />
      </div>

      <div class="cook-body">
        <main ref="step-area" class="step-area">
          <recipe-cook-step :step="currentStep" />
        </main>

        <aside v-if="showIngredients" class="ingredient-panel">
          <neb-content-header :title="$t('recipes.cook.ingredients')" type="section">
            <template v-if="portions" #actions>
              <div class="portion-controls">
                <neb-button small square type="tertiary-neutral" @click="decrementPortions()">
                  <icon name="material-symbols:remove-rounded" />
                </neb-button>

                {{ portions }}

                <neb-button small square type="tertiary-neutral" @click="incrementPortions()">
                  <icon name="material-symbols:add-rounded" />
                </neb-button>
              </div>
            </template>
          </neb-content-header>

          <div class="panel-list">
            <neb-badge v-for="subRecipe in subRecipes" :key="subRecipe.recipe.id.id.toString()">
              {{ subRecipe.recipe.name }}
            </neb-badge>

            <neb-checkbox
              v-for="(ingredient, index) in ingredients"
              :key="index"
              v-model="checkedIngredients"
              :value="index"
              class="panel-ingredient"
            >
              <span v-if="ingredient.amount" class="ingredient-amount">{{ roundNumberIfNeeded(ingredient.amount * portionRatio) }}</span>
              <span v-if="ingredient.unit" class="ingredient-unit">{{ ingredient.unit }}</span>
              <span>{{ ingredient.ingredient }}</span>
            </neb-checkbox>
          </div>
        </aside>
      </div>

      <footer class="cook-footer">
        <neb-button type="secondary-neutral" :disabled="stepIndex === 0" @click="goToStep(stepIndex - 1)">
          <icon name="material-symbols:arrow-back-rounded" />
          <span class="hide-on-mobile">{{ $t('recipes.cook.previous') }}</span>
        </neb-button>

        <neb-button v-if="stepIndex >= steps.length - 1" @click="isOpen = false">
          <icon name="material-symbols:check-rounded" />
          <span>{{ $t('recipes.cook.finish') }}</span>
        </neb-button>

        <neb-button v-else @click="goToStep(stepIndex + 1)">
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
  min-height: 100%;
  background: var(--neb-bg-page);
}

.cook-header {
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

.recipe-name {
  font-weight: 600;
  color: var(--neb-text);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.step-counter {
  font-size: var(--text-sm);
  color: var(--neb-text-subtle);
}

.progress-track {
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

.step-area {
  flex: 1;
  display: flex;
  align-items: center;
  padding: var(--space-12) var(--space-8);
  overflow-y: auto;
}

.ingredient-panel {
  width: 340px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  padding: var(--space-6);
  border-left: 1px solid var(--neb-border-subtle);
  background: var(--neb-bg-raised);
  overflow-y: auto;
}

.portion-controls {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.panel-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  align-items: flex-start;
}

.panel-ingredient {
  .ingredient-amount,
  .ingredient-unit {
    font-weight: 600;
    color: var(--neb-text);
  }
}

.cook-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  padding: var(--space-4);
  border-top: 1px solid var(--neb-border-subtle);
}

@media (--tablet-viewport) {
  .step-area {
    padding: var(--space-6) var(--space-4);
    align-items: flex-start;
  }

  .cook-body {
    flex-direction: column;
  }

  .ingredient-panel {
    width: 100%;
    border-left: none;
    border-top: 1px solid var(--neb-border-subtle);
  }

  .hide-on-mobile {
    display: none;
  }
}
</style>
