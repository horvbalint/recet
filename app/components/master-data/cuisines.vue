<script setup lang="ts">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { OutCuisine } from '~/db'

const getQuery = surql`SELECT * FROM cuisine WHERE household = type::thing(${householdGap}) ORDER BY name ASC`

const columns: Columns<OutCuisine> = {
  name: { text: 'Name' },
  flag: { text: 'Flag' },
  color: { text: 'Color' },
}
</script>

<template>
  <master-data-layout
    table="cuisine"
    name="cuisine"
    icon="material-symbols:public"
    :get-query
    :columns="columns"
  >
    <template #td-flag="{ original }">
      <span v-if="original" class="flag-emoji">{{ original }}</span>
      <span v-else class="no-flag">—</span>
    </template>

    <template #td-color="{ original }">
      <div class="color-display">
        <div class="color-indicator" :style="{ background: original }" />
        <span class="color-value">{{ original }}</span>
      </div>
    </template>

    <template #modal="{ close, afterSave, docToEdit }">
      <cuisine-master-data-modal
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

.flag-emoji {
  font-size: var(--text-lg);
}

.no-flag {
  color: var(--neutral-color-400);
  font-style: italic;
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
