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
  background: color-mix(in oklab, v-bind('tag.color') 10%, var(--neb-bg-raised));
  border-color: color-mix(in oklab, v-bind('tag.color') 70%, var(--neb-bg-raised));
}

.dark-mode {
  .badge {
    background: color-mix(in oklab, v-bind('tag.color') 20%, var(--neb-bg));
    border-color: color-mix(in oklab, v-bind('tag.color') 60%, var(--neb-bg));
  }
}
</style>
