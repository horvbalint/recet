<script setup lang="ts">
import type { OutMeal } from '~/db'

const { data, status, refresh } = await useAsyncData('meals', async () => {
  const [result] = await db.query<[OutMeal[]]>(surql`SELECT * FROM meal ORDER BY name ASC`)
  return result || []
})

const columns = {
  name: { text: 'Name' },
  color: { text: 'Color' }
}

async function handleCreate(formData: Record<string, any>) {
  try {
    await db.query(surql`CREATE meal CONTENT ${formData}`)
    await refresh()
  } catch (error) {
    console.error('Failed to create meal:', error)
  }
}
</script>

<template>
  <master-data-layout
    :data="data"
    :status="status"
    :refresh="refresh"
    :columns="columns"
    create-button-text="Add Meal Type"
    create-modal-title="Create New Meal Type"
    create-modal-icon="material-symbols:restaurant-rounded"
    :handle-create
  >
    <template #td-color="{ original }">
      <div class="color-display">
        <div class="color-indicator" :style="{ background: original }"></div>
        <span class="color-value">{{ original }}</span>
      </div>
    </template>

    <template #modal-form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
      
      <neb-input v-model="data.color" label="Color" type="color" required />
    </template>
  </master-data-layout>
</template>

<style scoped>
.color-display {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.color-indicator {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: 1px solid var(--neutral-color-200);
  flex-shrink: 0;
}

.color-value {
  font-family: monospace;
  font-size: var(--text-sm);
  color: var(--neutral-color-600);
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
