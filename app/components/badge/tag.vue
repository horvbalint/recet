<script setup lang="ts">
import type { InRecipeTag } from '~/db'

defineProps<{
  tag: Pick<InRecipeTag, 'name' | 'color' | 'icon'>
  small?: boolean
}>()
</script>

<template>
  <neb-badge :small class="badge">
    {{ tag.icon }}
    {{ tag.name }}
  </neb-badge>
</template>

<style scoped>
.badge {
  background: color-mix(in oklab, v-bind('tag.color') 10%, white);
  border-color: color-mix(in oklab, v-bind('tag.color') 70%, white);
}

.dark-mode {
  .badge {
    background: color-mix(in oklab, v-bind('tag.color') 10%, var(--neutral-color-950));
    border-color: color-mix(in oklab, v-bind('tag.color') 50%, var(--neutral-color-950));
  }
}
</style>
