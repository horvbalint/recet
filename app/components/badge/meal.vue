<script setup lang="ts">
import type { InMeal } from '~/db'

defineProps<{
  meal: Pick<InMeal, 'name' | 'color'>
  small?: boolean
}>()
</script>

<template>
  <neb-badge :small class="badge">
    {{ meal.name }}
  </neb-badge>
</template>

<style scoped>
.badge {
  background: color-mix(in oklab, v-bind('meal.color') 10%, white);
  border-color: color-mix(in oklab, v-bind('meal.color') 70%, white);
}

.dark-mode {
  .badge {
    background: color-mix(in oklab, v-bind('meal.color') 20%, var(--neutral-color-950));
    border-color: color-mix(in oklab, v-bind('meal.color') 60%, var(--neutral-color-950));
  }
}
</style>
