<script setup lang="ts">
import type { StepDuration } from '~/composables/cook'

defineProps<{
  step: string
  durations: StepDuration[]
  runningTimers: Map<number, { remainingSeconds: number, isFinished: boolean }>
}>()
defineEmits<{
  startTimer: [duration: StepDuration]
  cancelTimer: [duration: StepDuration]
}>()
</script>

<template>
  <div class="cook-step">
    <p class="step-text">
      {{ step }}
    </p>

    <div v-if="durations.length" class="step-timers">
      <recipe-cook-timer
        v-for="duration in durations"
        :key="duration.seconds"
        :duration
        :remaining-seconds="runningTimers.get(duration.seconds)?.remainingSeconds"
        :is-finished="runningTimers.get(duration.seconds)?.isFinished"
        @start="$emit('startTimer', duration)"
        @cancel="$emit('cancelTimer', duration)"
      />
    </div>
  </div>
</template>

<style scoped>
.cook-step {
  display: flex;
  flex-direction: column;
  gap: var(--space-8);
  align-items: flex-start;
}

.step-text {
  font-size: 32px;
  line-height: 1.45;
  color: var(--neb-text);
  white-space: pre-wrap;
}

.step-timers {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-3);
}

@media (--tablet-viewport) {
  .cook-step {
    gap: var(--space-6);
  }

  .step-text {
    font-size: 24px;
  }
}
</style>
