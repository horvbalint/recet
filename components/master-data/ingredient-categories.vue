<script setup lang="ts">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { OutIngredientCategory } from '~/db'

const getQuery = surql`SELECT * FROM ingredient_category ORDER BY name ASC`

const columns: Columns<OutIngredientCategory> = {
  name: { text: 'Name' }
}
</script>

<template>
  <master-data-layout
    table="ingredient_category"
    name="category"
    icon="material-symbols:category-rounded"
    :get-query
    :columns="columns"
  >
    <template #modal="{ close, afterSave, docToEdit }">
      <ingredient-category-master-data-modal
        :model-value="true"
        @update:model-value="close()"
        :initial-data="docToEdit"
        @saved="afterSave()"
      />
    </template>
  </master-data-layout>
</template>
