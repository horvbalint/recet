<script setup lang="ts">
const activeTable = ref <'unit' | 'meal' | 'cuisine' | 'recipe_tag' | 'ingredient' | 'ingredient_category' | 'shop'> ('unit')
const tabs = {
  unit: { text: 'Units', icon: 'material-symbols:straighten-outline' },
  meal: { text: 'Meal Types', icon: 'material-symbols:restaurant-rounded' },
  cuisine: { text: 'Cuisines', icon: 'material-symbols:public' },
  recipe_tag: { text: 'Tags', icon: 'material-symbols:tag-rounded' },
  ingredient_category: { text: 'Categories', icon: 'material-symbols:category-outline-rounded' },
  shop: { text: 'Shops', icon: 'material-symbols:store-outline' },
  ingredient: { text: 'Ingredients', icon: 'material-symbols:inventory-2-outline-rounded' },
}
</script>

<template>
  <nuxt-layout name="app">
    <template #content-header>
      <neb-content-header
        title="Master Data Management"
        description="Manage units, meal types, cuisines, tags, ingredients, categories, and shops for your recipes"
        type="page"
        has-separator
      />
    </template>

    <div class="content-wrapper">
      <neb-tabs v-model="activeTable" :tabs="tabs" />

      <master-data-units v-if="activeTable === 'unit'" />
      <master-data-meals v-if="activeTable === 'meal'" />
      <master-data-cuisines v-if="activeTable === 'cuisine'" />
      <master-data-tags v-if="activeTable === 'recipe_tag'" />
      <master-data-ingredient-categories v-if="activeTable === 'ingredient_category'" />
      <master-data-shops v-if="activeTable === 'shop'" />
      <master-data-ingredients v-if="activeTable === 'ingredient'" />
    </div>
  </nuxt-layout>
</template>

<style scoped>
.content-wrapper {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}
</style>
