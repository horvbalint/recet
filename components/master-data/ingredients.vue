<script setup lang="ts">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { OutIngredient, OutIngredientCategory } from '~/db'

const getQuery =surql`SELECT * FROM ingredient ORDER BY name ASC FETCH category`

const { data: categories } = await useAsyncData('ingredient-categories-options', async () => {
  const [result] = await db.query<[OutIngredientCategory[]]>(surql`SELECT id, name FROM ingredient_category ORDER BY name ASC`)
  return result || []
})

const columns: Columns<OutIngredient> = {
  name: { text: 'Name' },
  category: { text: 'Category' }
}

function transformBeforeSave(formData: OutIngredient) {
  return {
    ...formData,
    category: formData.category?.id
  }
}
</script>

<template>
  <master-data-layout
    table="ingredient"
    name="ingredient"
    icon="material-symbols:inventory-2-outline-rounded"
    :get-query
    :columns="columns"
    :transform-before-create="transformBeforeSave"
    :transform-before-edit="transformBeforeSave"
  >
    <template #td-category="{ original }">
      <neb-tag v-if="original" small>{{ original.name }}</neb-tag>
      <span v-else class="no-category">—</span>
    </template>

    <template #modal-form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
      
      <neb-select 
        v-model="data.category"
        label="Category" 
        :options="categories!"
        label-key="name"        
        track-by-key="name"
        placeholder="Select a category"
        allow-empty
      />
    </template>
  </master-data-layout>
</template>

<style scoped>
.no-category {
  color: var(--neutral-color-400);
  font-style: italic;
}
</style>
