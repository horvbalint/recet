<script setup lang="ts">
import type { RecordId } from 'surrealdb'
import type { StepDuration } from '~/composables/cook'

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

const { locale } = useI18n()

const stepIndex = ref(0)
const showIngredients = ref(!isMobile.value)
const checkedIngredients = ref<number[]>([])

const stepDurations = computed(() => props.steps.map(step => parseStepDurations(step, locale.value)))

const currentStep = computed(() => props.steps[stepIndex.value] ?? '')
const currentStepDurations = computed(() => stepDurations.value[stepIndex.value] ?? [])

function goToStep(index: number) {
  stepIndex.value = Math.min(Math.max(index, 0), props.steps.length - 1)
}

// TIMERS
interface RunningTimer {
  stepIndex: number
  seconds: number
  endsAt: number
  hasFired: boolean
}

const timers = ref<RunningTimer[]>([])

// the remaining time is derived from a timestamp instead of being counted down, so that a
// backgrounded tab - where intervals get throttled - still shows the right value on return
const now = ref(Date.now())
const { pause: pauseClock, resume: resumeClock } = useIntervalFn(() => now.value = Date.now(), 500, { immediate: false })

function remainingSecondsOf(timer: RunningTimer) {
  return Math.max(0, Math.ceil((timer.endsAt - now.value) / 1000))
}

const currentStepTimers = computed(() => {
  const byDuration = new Map<number, { remainingSeconds: number, isFinished: boolean }>()

  for (const timer of timers.value) {
    if (timer.stepIndex !== stepIndex.value)
      continue

    const remainingSeconds = remainingSecondsOf(timer)
    byDuration.set(timer.seconds, { remainingSeconds, isFinished: remainingSeconds === 0 })
  }

  return byDuration
})

const otherStepTimers = computed(() => timers.value.filter(timer => timer.stepIndex !== stepIndex.value))

watch(now, () => {
  for (const timer of timers.value) {
    if (timer.hasFired || remainingSecondsOf(timer) > 0)
      continue

    timer.hasFired = true
    playCookAlarm()
  }
})

function startTimer(duration: StepDuration) {
  primeCookAlarm()

  timers.value.push({
    stepIndex: stepIndex.value,
    seconds: duration.seconds,
    endsAt: Date.now() + duration.seconds * 1000,
    hasFired: false,
  })
}

function cancelTimer(duration: StepDuration) {
  timers.value = timers.value.filter(timer => timer.stepIndex !== stepIndex.value || timer.seconds !== duration.seconds)
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
    timers.value = []
    checkedIngredients.value = []
    showIngredients.value = !isMobile.value

    resumeClock()
    keepScreenAwake()
  }
  else {
    timers.value = []
    pauseClock()
    releaseWakeLock()
  }
})

onBeforeUnmount(() => {
  pauseClock()
  releaseWakeLock()
})

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
        <div class="progress-value" :style="{ transform: `scaleX(${(stepIndex + 1) / steps.length})` }" />
      </div>

      <div class="cook-body">
        <main ref="step-area" class="step-area">
          <recipe-cook-step
            :step="currentStep"
            :durations="currentStepDurations"
            :running-timers="currentStepTimers"
            @start-timer="startTimer($event)"
            @cancel-timer="cancelTimer($event)"
          />
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

        <div class="other-timers">
          <button
            v-for="timer in otherStepTimers"
            :key="`${timer.stepIndex}-${timer.seconds}`"
            class="other-timer"
            :class="{ finished: remainingSecondsOf(timer) === 0 }"
            type="button"
            @click="goToStep(timer.stepIndex)"
          >
            <icon name="material-symbols:timer-outline-rounded" />
            <span>{{ formatTimerValue(remainingSecondsOf(timer)) }}</span>
            <span class="timer-step">{{ $t('recipes.cook.timer.onStep', { step: timer.stepIndex + 1 }) }}</span>
          </button>
        </div>

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

.other-timers {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  justify-content: center;
}

.other-timer {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-1) var(--space-3);
  border: 1px solid var(--neb-border);
  border-radius: var(--radius-large);
  background: var(--neb-bg-raised);
  font-size: var(--text-sm);
  font-variant-numeric: tabular-nums;
  color: var(--neb-text-subtle);
  cursor: pointer;

  &.finished {
    border-color: var(--neb-border-success-strong);
    color: var(--neb-text-success);
  }
}

.timer-step {
  color: var(--neb-text-subtle);
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

  .timer-step {
    display: none;
  }
}
</style>
