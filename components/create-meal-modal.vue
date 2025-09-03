<script setup lang="ts">
import type { OutMeal } from '~/db'

const props = defineProps<{
  searchTerm?: string
}>()

const modelValue = defineModel<boolean>({ required: true })

const emit = defineEmits<{
  'created': [item: OutMeal]
}>()

function handleSuccess(item: OutMeal) {
  emit('created', item)
}
</script>

<template>
  <master-data-modal
    v-model="modelValue"
    table="meal"
    name="Meal"
    icon="material-symbols:restaurant"
    :initial-data="{ name: searchTerm || '' }"
    @success="handleSuccess"
  >
    <template #form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
      
      <neb-input v-model="data.color" label="Color" type="color" required />
    </template>
  </master-data-modal>
</template>
