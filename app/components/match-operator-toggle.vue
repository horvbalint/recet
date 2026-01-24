<script setup lang="ts">
const modelValue = defineModel<'and' | 'or'>({ required: true })
</script>

<template>
  <neb-button-group>
    <neb-button :type="modelValue === 'and' ? 'secondary' : 'secondary-neutral'" small @click="modelValue = 'and'">
      All
    </neb-button>

    <neb-button :type="modelValue === 'or' ? 'secondary' : 'secondary-neutral'" small @click="modelValue = 'or'">
      Any
    </neb-button>
  </neb-button-group>
</template>
