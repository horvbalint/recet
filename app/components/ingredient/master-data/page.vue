<script setup lang="ts">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { BoundQuery } from 'surrealdb'
import type { InIngredient, OutIngredient, OutIngredientCategory } from '~/db'

interface OutIngredientWithCategory extends OutIngredient {
  category?: OutIngredientCategory
}

const { t } = useI18n()
// annotated so master-data-layout infers T, which the typed sortFunction below needs
const getQuery = computed(() => surql`SELECT * FROM ingredient WHERE household = ${currentHousehold.value!.id} ORDER BY name ASC FETCH category` as BoundQuery<[OutIngredientWithCategory]>)

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

// the row arrives with household and category fetched as objects, while the modal
// writes InIngredient, which wants record ids for both
function toInitialData(doc: OutIngredientWithCategory | null): Partial<InIngredient> | null {
  if (!doc)
    return null

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
        :initial-data="toInitialData(docToEdit)"
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
