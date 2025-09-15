<script setup lang="ts">
const activeTable = ref <'unit' | 'meal' | 'cuisine' | 'recipe_tag' | 'ingredient'> ('unit')
const tabs = {
  unit: { text: 'Units', icon: 'material-symbols:straighten-outline' },
  meal: { text: 'Meal Types', icon: 'material-symbols:restaurant-rounded' },
  cuisine: { text: 'Cuisines', icon: 'material-symbols:public' },
  recipe_tag: { text: 'Tags', icon: 'material-symbols:tag-rounded' },
  ingredient: { text: 'Ingredients', icon: 'material-symbols:inventory-2-outline-rounded' },
}
</script>

<template>
  <nuxt-layout name="app">
    <template #content-header>
      <neb-content-header
        title="Master Data Management"
        description="Manage units, meal types, cuisines, tags, and ingredients for your recipes"
        type="page"
      />

      <neb-tabs v-model="activeTable" :tabs="tabs" class="master-data-tabs" />
    </template>

    <master-data-units v-if="activeTable === 'unit'" />
    <master-data-meals v-if="activeTable === 'meal'" />
    <master-data-cuisines v-if="activeTable === 'cuisine'" />
    <master-data-tags v-if="activeTable === 'recipe_tag'" />
    <master-data-ingredients v-if="activeTable === 'ingredient'" />
  </nuxt-layout>
</template>

<style scoped>
.master-data-tabs {
  margin-top: var(--space-6);
  margin-bottom: var(--space-6);
}
</style>
