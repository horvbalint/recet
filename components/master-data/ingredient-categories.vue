<script setup lang="ts">
interface IngredientCategory {
  id: string
  name: string
}

const { data, status, refresh } = await useAsyncData('ingredient-categories', async () => {
  const [result] = await db.query<[IngredientCategory[]]>(surql`
    SELECT * FROM ingredient_category ORDER BY name ASC
  `)
  return result || []
})

const columns = {
  name: { text: 'Name' }
}

async function handleCreate(formData: Record<string, any>) {
  try {
    await db.query(surql`CREATE ingredient_category CONTENT ${formData}`)
    await refresh()
  } catch (error) {
    console.error('Failed to create ingredient category:', error)
  }
}
</script>

<template>
  <master-data-layout
    :data="data"
    :status="status"
    :refresh="refresh"
    :columns="columns"
    create-button-text="Add Category"
    create-modal-title="Create New Ingredient Category"
    create-modal-icon="material-symbols:category-rounded"
    :handle-create
  >
    <template #modal-form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
    </template>
  </master-data-layout>
</template>
