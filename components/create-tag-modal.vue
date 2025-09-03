<script setup lang="ts">
import type { OutRecipeTag } from '~/db'

const props = defineProps<{
  searchTerm?: string
}>()

const modelValue = defineModel<boolean>({ required: true })

const emit = defineEmits<{
  'created': [item: OutRecipeTag]
}>()

function handleSuccess(item: OutRecipeTag) {
  emit('created', item)
}
</script>

<template>
  <master-data-modal
    v-model="modelValue"
    table="recipe_tag"
    name="Tag"
    icon="material-symbols:tag"
    :initial-data="{ name: searchTerm || '' }"
    @success="handleSuccess"
  >
    <template #form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
      
      <neb-input v-model="data.color" label="Color" type="color" required />
      
      <neb-input v-model="data.icon" label="Icon" placeholder="material-symbols:icon-name" />
    </template>
  </master-data-modal>
</template>
