<script setup lang="ts">
const activeTable = ref < 'unit' | 'meal' | 'cuisine' | 'recipe_tag' | 'ingredient' > ('unit')

const tabs = {
  unit: { text: 'Units', icon: 'material-symbols:straighten-outline' },
  meal: { text: 'Meal Types', icon: 'material-symbols:restaurant-rounded' },
  cuisine: { text: 'Cuisines', icon: 'material-symbols:public' },
  recipe_tag: { text: 'Tags', icon: 'material-symbols:tag-rounded' },
  ingredient: { text: 'Ingredients', icon: 'material-symbols:inventory-2-outline-rounded' },
}
</script>

<template>
  <div class="master-data">
    <div class="master-data-container">
      <neb-content-header
        title="Master Data Management"
        description="Manage units, meal types, cuisines, tags, and ingredients for your recipes"
        type="page"
      >
        <template #actions>
          <neb-button type="tertiary-neutral" @click="$router.push('/')">
            <icon name="material-symbols:arrow-back-rounded" />
            Back to Recipes
          </neb-button>
        </template>
      </neb-content-header>

      <neb-tabs v-model="activeTable" :tabs="tabs" class="master-data-tabs" />

      <main class="tab-content">
        <master-data-units v-if="activeTable === 'unit'" />
        <master-data-meals v-if="activeTable === 'meal'" />
        <master-data-cuisines v-if="activeTable === 'cuisine'" />
        <master-data-tags v-if="activeTable === 'recipe_tag'" />
        <master-data-ingredients v-if="activeTable === 'ingredient'" />
      </main>
    </div>
  </div>
</template>

<style scoped>
.master-data {
  min-height: 100vh;
  background: var(--neutral-color-25);
}

.master-data-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: var(--space-6);
}

.master-data-tabs {
  margin-top: var(--space-6);
  margin-bottom: var(--space-6);
}

@media (--tablet-viewport) {
  .master-data-container {
    padding: var(--space-4);
  }
}

@media (--mobile-lg-viewport) {
  .master-data-container {
    padding: var(--space-3);
  }
}
</style>
