<script setup lang="ts">
import type { InMeal, OutMeal } from '~/db'

defineProps<{
  initialData?: Partial<InMeal> | null
}>()

const emit = defineEmits<{
  saved: [item: OutMeal]
}>()

const modelValue = defineModel<boolean>({ required: true })

function handleSave(item: OutMeal) {
  emit('saved', item)
}
</script>

<template>
  <master-data-modal
    v-model="modelValue"
    table="meal"
    name="meal type"
    icon="material-symbols:restaurant-rounded"
    :initial-data
    @saved="handleSave"
  >
    <template #form="{ data }">
      <neb-input v-model="data.name" label="Name" required />

      <neb-input v-model="data.color" label="Color" type="color" required />
    </template>
  </master-data-modal>
</template>
