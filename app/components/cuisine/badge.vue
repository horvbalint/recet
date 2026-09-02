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
  background: color-mix(in oklab, v-bind('cuisine.color') 10%, var(--neb-bg-raised));
  border-color: color-mix(in oklab, v-bind('cuisine.color') 70%, var(--neb-bg-raised));
}

.dark-mode {
  .badge {
    background: color-mix(in oklab, v-bind('cuisine.color') 20%, var(--neb-bg));
    border-color: color-mix(in oklab, v-bind('cuisine.color') 60%, var(--neb-bg));
  }
}
</style>
