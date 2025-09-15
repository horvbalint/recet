<script setup lang="ts">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { OutIngredient } from '~/db'

const getQuery = surql`SELECT * FROM ingredient WHERE household = type::thing(${householdGap}) ORDER BY name ASC FETCH category`

const columns: Columns<OutIngredient> = {
  name: { text: 'Name' },
  category: { text: 'Category' },
}
</script>

<template>
  <master-data-layout
    table="ingredient"
    name="ingredient"
    icon="material-symbols:inventory-2-outline-rounded"
    :get-query
    :columns="columns"
  >
    <template #td-category="{ original }">
      <neb-tag v-if="original" small>
        {{ original.name }}
      </neb-tag>
      <span v-else class="no-category">—</span>
    </template>

    <template #modal="{ close, afterSave, docToEdit }">
      <ingredient-master-data-modal
        :model-value="true"
        :initial-data="docToEdit"
        @update:model-value="close()"
        @saved="afterSave()"
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
