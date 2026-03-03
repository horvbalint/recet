<script setup lang="ts">
const { t } = useI18n()

const columns = computed(() => ({
  name: { text: t('masterData.mealRule.columns.name') },
  conditionCount: { text: t('masterData.mealRule.columns.conditionCount') },
}))

const getQuery = surql`
  SELECT *, array::len(
    array::flatten([
      include.meals.items,
      include.tags.items,
      include.cuisines.items,
      include.ingredients.items
    ])
  ) + array::len(
    array::flatten([
      exclude.meals,
      exclude.tags,
      exclude.cuisines,
      exclude.ingredients
    ])
  ) AS conditionCount
  FROM meal_rule
  WHERE household = ${currentHousehold.value!.id}
  ORDER BY updated_at DESC
`
</script>

<template>
  <master-data-layout
    table="meal_rule"
    :columns="columns"
    :get-query="getQuery"
    :name="$t('masterData.mealRule.name')"
    icon="material-symbols:rule-rounded"
  >
    <template #modal="{ afterSave, close, docToEdit }">
      <meal-rule-master-data-modal
        :model-value="true"
        :initial-data="docToEdit"
        @update:model-value="close()"
        @saved="afterSave()"
      />
    </template>
  </master-data-layout>
</template>
