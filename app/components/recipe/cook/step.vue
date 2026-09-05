<script setup lang="ts">
defineProps<{
  step: string
}>()
</script>

<template>
  <p class="cook-step">
    {{ step }}
  </p>
</template>

<style scoped>
.cook-step {
  font-size: 32px;
  line-height: 1.45;
  color: var(--neb-text);
  white-space: pre-wrap;
}

@media (--tablet-viewport) {
  .cook-step {
    font-size: 24px;
  }
}
</style>
