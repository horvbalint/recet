<script setup lang="ts">
import type { OutCuisine } from '~/db'

const { data, status, refresh } = await useAsyncData('cuisines', async () => {
  const [result] = await db.query<[OutCuisine[]]>(surql`SELECT * FROM cuisine ORDER BY name ASC`)
  return result || []
})

const columns = {
  name: { text: 'Name' },
  flag: { text: 'Flag' },
  color: { text: 'Color' }
}

// Flag emoji options
const flagOptions = [
  '🇺🇸', '🇬🇧', '🇫🇷', '🇮🇹', '🇪🇸', '🇩🇪', '🇯🇵', '🇨🇳', '🇮🇳', '🇰🇷',
  '🇹🇭', '🇻🇳', '🇲🇽', '🇧🇷', '🇦🇷', '🇵🇪', '🇨🇦', '🇦🇺', '🇷🇺', '🇺🇦',
  '🇵🇱', '🇨🇿', '🇭🇺', '🇷🇴', '🇬🇷', '🇹🇷', '🇪🇬', '🇲🇦', '🇿🇦', '🇳🇬',
  '🇮🇱', '🇱🇧', '🇸🇦', '🇦🇪', '🇮🇷', '🇵🇰', '🇧🇩', '🇱🇰', '🇳🇵', '🇲🇾',
  '🇸🇬', '🇮🇩', '🇵🇭', '🇰🇭', '🇱🇦', '🇲🇲', '🇪🇹', '🇰🇪', '🇬🇭', '🇨🇮'
]

async function handleCreate(formData: Record<string, any>) {
  try {
    await db.query(surql`CREATE cuisine CONTENT ${formData}`)
    await refresh()
  } catch (error) {
    console.error('Failed to create cuisine:', error)
  }
}
</script>

<template>
  <master-data-layout
    :data="data"
    :status="status"
    :refresh="refresh"
    :columns="columns"
    create-button-text="Add Cuisine"
    create-modal-title="Create New Cuisine"
    create-modal-icon="material-symbols:public"
    :handle-create
  >
    <template #td-flag="{ original }">
      <span v-if="original" class="flag-emoji">{{ original }}</span>
      <span v-else class="no-flag">—</span>
    </template>

    <template #td-color="{ original }">
      <div class="color-display">
        <div class="color-indicator" :style="{ background: original }"></div>
        <span class="color-value">{{ original }}</span>
      </div>
    </template>

    <template #modal-form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
      
      <neb-input v-model="data.color" label="Color" type="color" required />
      
      <neb-select v-model="data.flag" label="Flag" no-search :options="flagOptions" placeholder="Select a flag" allow-empty />
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

.color-input-group {
  display: flex;
  gap: var(--space-2);
  align-items: center;
}

.color-picker {
  width: 60px;
  height: 40px;
  border: 1px solid var(--neutral-color-300);
  border-radius: var(--radius-default);
  cursor: pointer;
}

.color-input {
  flex: 1;
}

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

.flag-emoji {
  font-size: var(--text-lg);
}

.no-flag {
  color: var(--neutral-color-400);
  font-style: italic;
}
</style>
