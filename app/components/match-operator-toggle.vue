<script setup lang="ts">
const modelValue = defineModel<'and' | 'or'>({ required: true })

const options = [
  { text: 'All', value: 'and' },
  { text: 'Any', value: 'or' },
]
</script>

<template>
  <neb-radio-group v-model="modelValue" small :options />
</template>
