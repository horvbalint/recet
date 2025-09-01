<script setup lang="ts">
import type { InUnit, OutUnit } from '~/db'

const { data, status, refresh } = await useAsyncData('units', async () => {
  const [result] = await db.query<[OutUnit[]]>(surql`SELECT * FROM unit ORDER BY name ASC`)
  return result || []
})

const columns = {
  name: { text: 'Name' }
}

async function handleCreate(formData: InUnit) {
  try {
    await db.query(surql`CREATE unit CONTENT ${formData}`)
    await refresh()
  } catch (error) {
    console.error('Failed to create unit:', error)
  }
}
</script>

<template>
  <master-data-layout
    :data="data"
    :status="status"
    :refresh="refresh"
    :columns="columns"
    create-button-text="Add Unit"
    create-modal-title="Create New Unit"
    create-modal-icon="material-symbols:straighten-outline"
    :handle-create
  >
    <template #modal-form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
    </template>
  </master-data-layout>
</template>

<style scoped>
.form-field {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.field-label {
  font-size: var(--text-sm);
  font-weight: var(--font-weight-medium);
  color: var(--neutral-color-700);
}

.required {
  color: var(--error-color-500);
}
</style>
