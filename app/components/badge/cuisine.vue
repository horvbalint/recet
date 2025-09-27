<script setup lang="ts">
import type { OutCuisine } from '~/db'

defineProps<{
  cuisine: Pick<OutCuisine, 'name' | 'color' | 'flag'>
  small?: boolean
}>()
</script>

<template>
  <neb-badge class="badge" :small>
    <span v-if="cuisine.flag">{{ cuisine.flag }}</span>
    {{ cuisine.name }}
  </neb-badge>
</template>

<style scoped>
.badge {
  background: color-mix(in oklab, v-bind('cuisine.color') 10%, white);
  border-color: color-mix(in oklab, v-bind('cuisine.color') 70%, white);
}

.dark-mode {
  .badge {
    background: color-mix(in oklab, v-bind('cuisine.color') 10%, var(--neutral-color-950));
    border-color: color-mix(in oklab, v-bind('cuisine.color') 50%, var(--neutral-color-950));
  }
}
</style>
