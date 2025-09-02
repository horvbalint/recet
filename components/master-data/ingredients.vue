<script setup lang="ts">
import type { InIngredient, OutIngredient, OutIngredientCategory } from '~/db'

const { data, status, refresh } = await useAsyncData('ingredients', async () => {
  const [result] = await db.query<[OutIngredient[]]>(surql`SELECT * FROM ingredient ORDER BY name ASC FETCH category`)
  return result || []
})

const { data: categories } = await useAsyncData('ingredient-categories-options', async () => {
  const [result] = await db.query<[OutIngredientCategory[]]>(surql`SELECT id, name FROM ingredient_category ORDER BY name ASC`)
  return result || []
})

const columns = {
  name: { text: 'Name' },
  category: { text: 'Category' }
}

async function handleCreate(formData: InIngredient) {
  try {
    await db.query(surql`INSERT INTO ingredient ${{
      ...formData,
      category: formData.category?.id
    }}`)
    await refresh()
  } catch (error) {
    console.error('Failed to create ingredient:', error)
  }
}

async function handleEdit(formData: InIngredient) {
  try {
    await db.query(surql`UPDATE ${formData.id} MERGE ${{
      ...formData,
      category: formData.category?.id
    }}`)
    await refresh()
  } catch (error) {
    console.error('Failed to edit ingredient:', error)
  }
}

async function handleDelete(formData: InIngredient) {
  try {
    await db.query(surql`DELETE ${formData.id}`)
    await refresh()
  } catch (error) {
    console.error('Failed to delete ingredient:', error)
  }
}
</script>

<template>
  <master-data-layout
    :data="data"
    :status="status"
    :refresh="refresh"
    :columns="columns"
    create-button-text="Add Ingredient"
    create-modal-title="Create New Ingredient"
    create-modal-icon="material-symbols:inventory-2-outline-rounded"
    :handle-create
    :handle-edit
    :handle-delete
  >
    <template #td-category="{ original }">
      <neb-tag v-if="original" small>{{ original.name }}</neb-tag>
      <span v-else class="no-category">—</span>
    </template>

    <template #modal-form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
      
      <neb-select 
        v-model="data.categorySelection"
        label="Category" 
        :options="categories!"
        label-key="name"        
        track-by-key="id"
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
