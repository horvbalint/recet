<script setup lang="ts">
import type { InIngredientCategory, OutIngredientCategory } from '~/db'

defineProps<{
  initialData?: Partial<InIngredientCategory> | null
}>()

const modelValue = defineModel<boolean>({required: true})

const emit = defineEmits<{
  'saved': [item: OutIngredientCategory]
}>()

function handleSave(item: OutIngredientCategory) {
  emit('saved', item)
}
</script>

<template>
  <master-data-modal
    v-model="modelValue"
    table="ingredient_category"
    name="category"
    icon="material-symbols:category-rounded"
    :initial-data
    @saved="handleSave"
  >
    <template #form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
    </template>
  </master-data-modal>
</template>
