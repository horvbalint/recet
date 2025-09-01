<script setup lang="ts">
import type { OutIngredient } from '~/db'

const { data, status, refresh } = await useAsyncData('ingredients', async () => {
  const [result] = await db.query<[OutIngredient[]]>(surql`SELECT * FROM ingredient ORDER BY name ASC FETCH category`)
  return result || []
})

const columns = {
  name: { text: 'Name' },
  category: { text: 'Category' }
}

async function handleCreate(formData: Record<string, any>) {
  try {
    await db.query(surql`INSERT INTO ingredient ${formData}`)
    await refresh()
  } catch (error) {
    console.error('Failed to create ingredient:', error)
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
  >
    <template #td-category="{ original }">
      <neb-tag v-if="original" small>{{ original.name }}</neb-tag>
      <span v-else class="no-category">—</span>
    </template>

    <template #modal-form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
      
      <neb-input v-model="data.category" label="Category" />
    </template>
  </master-data-layout>
</template>

<style scoped>
.no-category {
  color: var(--neutral-color-400);
  font-style: italic;
}

.action-icon {
  font-size: 20px !important;
  color: var(--neutral-color-600);
  cursor: pointer;
  transition: all var(--duration-default);
}

.action-icon:hover {
  color: var(--neutral-color-900);
}
</style>
