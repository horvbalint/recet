<script setup lang="ts">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { OutMeal } from '~/db'

const getQuery = surql`SELECT * FROM meal WHERE household = type::thing(${householdGap}) ORDER BY name ASC`

const columns: Columns<OutMeal> = {
  name: { text: 'Name' },
  color: { text: 'Color' },
}
</script>

<template>
  <master-data-layout
    table="meal"
    name="meal type"
    icon="material-symbols:restaurant-rounded"
    :get-query
    :columns="columns"
  >
    <template #td-color="{ original }">
      <div class="color-display">
        <div class="color-indicator" :style="{ background: original }" />
        <span class="color-value">{{ original }}</span>
      </div>
    </template>

    <template #modal="{ close, afterSave, docToEdit }">
      <meal-master-data-modal
        :model-value="true"
        :initial-data="docToEdit"
        @update:model-value="close()"
        @saved="afterSave()"
      />
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

.dark-mode {
  .color-indicator {
    border: 1px solid var(--neutral-color-700);
  }

  .color-value {
    color: var(--neutral-color-300);
  }
}
</style>
