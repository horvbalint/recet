<script setup lang="ts">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { OutIngredientCategory } from '~/db'

const { t } = useI18n()
const getQuery = computed(() => surql`SELECT * FROM ingredient_category WHERE household = ${currentHousehold.value!.id} ORDER BY name ASC`)

const columns = computed(() => ({
  name: { text: t('masterData.ingredientCategory.columns.name') },
}) satisfies Columns<OutIngredientCategory>)
</script>

<template>
  <master-data-layout
    table="ingredient_category"
    :name="$t('masterData.ingredientCategory.name')"
    icon="material-symbols:category-outline-rounded"
    :get-query
    :columns
  >
    <template #modal="{ close, afterSave, docToEdit }">
      <ingredient-category-master-data-modal
        :model-value="true"
        :initial-data="docToEdit"
        @update:model-value="close()"
        @saved="afterSave()"
      />
    </template>
  </master-data-layout>
</template>
