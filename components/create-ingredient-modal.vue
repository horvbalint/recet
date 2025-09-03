<script setup lang="ts">
import type { OutIngredient, OutIngredientCategory } from '~/db'

const props = defineProps<{
  searchTerm?: string
}>()

const modelValue = defineModel<boolean>({ required: true })

const emit = defineEmits<{
  'created': [item: OutIngredient]
}>()

const { data: categories } = await useAsyncData('ingredient-categories-options', async () => {
  const [result] = await db.query<[OutIngredientCategory[]]>(surql`SELECT id, name FROM ingredient_category ORDER BY name ASC`)
  return result || []
})

function transformBeforeCreate(data: any) {
  return {
    ...data,
    category: data.category?.id
  }
}

function handleSuccess(item: OutIngredient) {
  emit('created', item)
}
</script>

<template>
  <master-data-modal
    v-model="modelValue"
    table="ingredient"
    name="Ingredient"
    icon="material-symbols:inventory-2-outline-rounded"
    :initial-data="{ name: searchTerm || '' }"
    :transform-before-create="transformBeforeCreate"
    @success="handleSuccess"
  >
    <template #form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
      
      <neb-select 
        v-model="data.category"
        label="Category" 
        :options="categories || []"
        label-key="name"        
        track-by-key="name"
        placeholder="Select a category"
        allow-empty
      />
    </template>
  </master-data-modal>
</template>
