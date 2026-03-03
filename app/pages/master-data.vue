<script setup lang="ts">
const { t } = useI18n()

const route = useRoute()

type Table = 'unit' | 'meal' | 'cuisine' | 'recipe_tag' | 'ingredient' | 'ingredient_category' | 'shop' | 'meal_rule'
const activeTable = ref<Table>(route.query.table as Table || 'unit')

const tabs = computed(() => ({
  unit: { text: t('masterData.tabs.units'), icon: 'material-symbols:straighten-outline' },
  meal: { text: t('masterData.tabs.mealTypes'), icon: 'material-symbols:restaurant-rounded' },
  cuisine: { text: t('masterData.tabs.cuisines'), icon: 'material-symbols:public' },
  recipe_tag: { text: t('masterData.tabs.tags'), icon: 'material-symbols:tag-rounded' },
  ingredient_category: { text: t('masterData.tabs.categories'), icon: 'material-symbols:category-outline-rounded' },
  shop: { text: t('masterData.tabs.shops'), icon: 'material-symbols:store-outline' },
  ingredient: { text: t('masterData.tabs.ingredients'), icon: 'material-symbols:grocery' },
  meal_rule: { text: t('masterData.tabs.mealRules'), icon: 'material-symbols:rule-rounded' },
}))

watch(activeTable, () => navigateTo({ query: { table: activeTable.value } }))
</script>

<template>
  <page-layout>
    <template #content-header>
      <neb-content-header
        :title="$t('masterData.title')"
        :description="$t('masterData.description')"
        :type="pageHeaderType"
        has-separator
      />
    </template>

    <div class="content-wrapper">
      <neb-tabs v-model="activeTable" :tabs="tabs" />

      <unit-master-data-page v-if="activeTable === 'unit'" />
      <meal-master-data-page v-if="activeTable === 'meal'" />
      <cuisine-master-data-page v-if="activeTable === 'cuisine'" />
      <recipe-tag-master-data-page v-if="activeTable === 'recipe_tag'" />
      <ingredient-category-master-data-page v-if="activeTable === 'ingredient_category'" />
      <shop-master-data-page v-if="activeTable === 'shop'" />
      <ingredient-master-data-page v-if="activeTable === 'ingredient'" />
      <meal-rule-master-data-page v-if="activeTable === 'meal_rule'" />
    </div>
  </page-layout>
</template>

<style scoped>
.content-wrapper {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}
</style>
