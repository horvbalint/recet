<script setup lang="ts">
import type { StepDuration } from '~/composables/cook'

const props = defineProps<{
  duration: StepDuration
  remainingSeconds?: number
  isFinished?: boolean
}>()
defineEmits<{
  start: []
  cancel: []
}>()

const isRunning = computed(() => props.remainingSeconds !== undefined)

const progress = computed(() => {
  if (props.remainingSeconds === undefined)
    return 0

  return 1 - props.remainingSeconds / props.duration.seconds
})
</script>

<template>
  <button
    class="cook-timer"
    :class="{ running: isRunning, finished: isFinished }"
    type="button"
    @click="isRunning ? $emit('cancel') : $emit('start')"
  >
    <div class="progress" :style="{ transform: `scaleX(${progress})` }" />

    <div class="content">
      <icon :name="isFinished ? 'material-symbols:alarm-on-rounded' : 'material-symbols:timer-outline-rounded'" />

      <span v-if="isFinished">{{ $t('recipes.cook.timer.done') }}</span>
      <span v-else-if="remainingSeconds !== undefined">{{ formatTimerValue(remainingSeconds) }}</span>
      <span v-else>{{ duration.label }}</span>

      <icon v-if="isRunning" class="cancel-icon" name="material-symbols:close-rounded" />
    </div>
  </button>
</template>

<style scoped>
.cook-timer {
  position: relative;
  overflow: hidden;
  border: 1px solid var(--neb-border);
  border-radius: var(--radius-large);
  background: var(--neb-bg-raised);
  padding: var(--space-2) var(--space-4);
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--neb-text);
  cursor: pointer;
  transition: border-color var(--duration-default) ease;

  &:hover {
    border-color: var(--neb-border-primary-strong);
  }

  &.running {
    border-color: var(--neb-border-primary-strong);
  }

  &.finished {
    border-color: var(--neb-border-success-strong);
    color: var(--neb-text-success);
    animation: timer-pulse 1s ease-in-out infinite;
  }
}

.progress {
  position: absolute;
  inset: 0;
  transform-origin: left;
  background: var(--neb-bg-primary);
  transition: transform 1s linear;
}

.content {
  position: relative;
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-variant-numeric: tabular-nums;
}

.cancel-icon {
  opacity: 0.6;
}

@keyframes timer-pulse {
  50% {
    opacity: 0.55;
  }
}
</style>
