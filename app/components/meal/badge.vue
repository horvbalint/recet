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
  background: color-mix(in oklab, v-bind('meal.color') 10%, var(--neb-bg-raised));
  border-color: color-mix(in oklab, v-bind('meal.color') 70%, var(--neb-bg-raised));
}

.dark-mode {
  .badge {
    background: color-mix(in oklab, v-bind('meal.color') 20%, var(--neb-bg));
    border-color: color-mix(in oklab, v-bind('meal.color') 60%, var(--neb-bg));
  }
}
</style>
