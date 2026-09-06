<script setup lang="ts">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { InIngredient, OutIngredient, OutIngredientCategory } from '~/db'

interface OutIngredientWithCategory extends OutIngredient {
  category?: OutIngredientCategory
}

const { t } = useI18n()
const getQuery = computed(() => surql<[OutIngredientWithCategory]>`SELECT * FROM ingredient WHERE household = ${currentHousehold.value!.id} ORDER BY name ASC FETCH category`)

const columns = computed(() => ({
  name: {
    text: t('masterData.ingredient.columns.name'),
  },
  category: {
    text: t('masterData.ingredient.columns.category'),
    formatFunction: category => category?.name || '-',
    sortFunction: (a, b) => a.formatted.category.localeCompare(b.formatted.category),
  },
}) satisfies Columns<OutIngredientWithCategory>)

function toInIngredient(doc: OutIngredientWithCategory | null): Partial<InIngredient> | null {
  if (!doc)
    return null
  else
    return { ...doc, household: doc.household.id, category: doc.category?.id }
}
</script>

<template>
  <master-data-layout
    table="ingredient"
    :name="$t('masterData.ingredient.name')"
    icon="material-symbols:grocery"
    :get-query
    :columns
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
        :initial-data="toInIngredient(docToEdit)"
        @update:model-value="close()"
        @saved="afterSave()"
      />
    </template>
  </master-data-layout>
</template>

<style scoped>
.no-category {
  color: var(--neb-text-subtle);
  font-style: italic;
}
</style>
