<script setup lang="ts">
definePageMeta({
  layout: 'app',
})

const route = useRoute()

type Table = 'unit' | 'meal' | 'cuisine' | 'recipe_tag' | 'ingredient' | 'ingredient_category' | 'shop'
const activeTable = ref<Table>(route.query.table as Table || 'unit')

const tabs = {
  unit: { text: 'Units', icon: 'material-symbols:straighten-outline' },
  meal: { text: 'Meal Types', icon: 'material-symbols:restaurant-rounded' },
  cuisine: { text: 'Cuisines', icon: 'material-symbols:public' },
  recipe_tag: { text: 'Tags', icon: 'material-symbols:tag-rounded' },
  ingredient_category: { text: 'Categories', icon: 'material-symbols:category-outline-rounded' },
  shop: { text: 'Shops', icon: 'material-symbols:store-outline' },
  ingredient: { text: 'Ingredients', icon: 'material-symbols:grocery' },
}

watch(activeTable, () => navigateTo({ query: { table: activeTable.value } }))
</script>

<template>
  <page-layout>
    <template #content-header>
      <neb-content-header
        title="Master Data Management"
        description="Manage units, meal types, cuisines, tags, ingredients, categories, and shops for your recipes"
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
