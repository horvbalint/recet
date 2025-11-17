<script setup lang="ts">
import type { RecordId } from 'surrealdb'

definePageMeta({
  layout: 'app',
})

export interface Recipe {
  id: RecordId<'recipe'>
  name: string
  ingredients: number
  steps: number
  image_blur_hash?: string
  cooking_time_minutes?: number
  author: {
    username: string
  }
  cuisine?: {
    name: string
    color: string
    flag?: string
  }
  tags?: {
    name: string
    color: string
    icon?: string
  }[]
  meal?: {
    name: string
    color: string
  }[]
  created_at: string
  updated_at: string
}

const {
  recipes: {
    data: {
      pageIndex,
      recipes,
      recipeCount,
    },
    status,
    error,
    refresh,
  },
  filter: {
    conditions: {
      searchTerm,
      selectedCuisines,
      selectedTags,
      selectedMeals,
      selectedIngredients,
    },
    data: {
      data: filterData,
      status: filterDataStatus,
      refresh: queryFilterData,
    },
  },
} = useRecipeState()

const conditionCount = computed(() => selectedCuisines.value.length + selectedTags.value.length + selectedMeals.value.length + selectedIngredients.value.length)
const showFilter = ref(!!conditionCount.value)

async function toggleFilter() {
  if (!showFilter.value && !filterData.value)
    await queryFilterData()

  showFilter.value = !showFilter.value
}

const recipeLoader = useTemplateRef('recipe-loader')
const observer = new IntersectionObserver(([entry]) => {
  if (entry!.isIntersecting && status.value !== 'pending')
    pageIndex.value++
}, {
  rootMargin: '100px',
})

watch(recipeLoader, () => {
  if (recipeLoader.value)
    observer.observe(recipeLoader.value.$el)
  else
    observer!.disconnect()
})

onBeforeUnmount(() => {
  observer!.disconnect()
})
</script>

<template>
  <page-layout>
    <template #content-header>
      <neb-content-header
        title="Recipes"
        description="Discover and explore delicious recipes from our collection"
        :type="pageHeaderType"
        has-separator
      >
        <template v-if="recipes.length" #actions>
          <neb-button small type="primary" @click="$router.push('/recipe/create')">
            <icon name="material-symbols:add-rounded" />
            Add Recipe
          </neb-button>
        </template>
      </neb-content-header>
    </template>

    <div class="page-wrapper">
      <div class="search-filter-row">
        <div class="search-row">
          <neb-search-input v-model="searchTerm" lazy />

          <neb-button
            :type="conditionCount ? 'secondary' : 'secondary-neutral'"
            :disabled="filterDataStatus === 'pending'"
            :loading="filterDataStatus === 'pending'"
            small
            @click="toggleFilter()"
          >
            <icon name="material-symbols:filter-list-rounded" />
            <span class="filter-span">Filters</span>
            <span v-if="conditionCount">({{ conditionCount }})</span>
          </neb-button>
        </div>

        <div v-if="filterData" v-neb-expand="showFilter" class="filter-row">
          <neb-select
            v-model="selectedCuisines"
            placeholder="Filter by Cuisine"
            :options="filterData.cuisenes"
            label-key="name"
            track-by-key="id"
            :transform-fun="transformId"
            use-only-tracked-key
            multiple
            leading-icon="material-symbols:public"
          >
            <template #option="{ option }">
              <cuisine-badge :cuisine="option" />
            </template>

            <template #selection="{ selected }">
              <cuisine-badge v-for="cuisine in selected" :key="cuisine.trackValue.toString()" small :cuisine="cuisine.option" />
            </template>
          </neb-select>

          <neb-select
            v-model="selectedTags"
            placeholder="Filter by Tags"
            :options="filterData.tags"
            label-key="name"
            track-by-key="id"
            :transform-fun="transformId"
            use-only-tracked-key
            multiple
            leading-icon="material-symbols:tag-rounded"
          >
            <template #option="{ option }">
              <recipe-tag-badge :tag="option" />
            </template>

            <template #selection="{ selected }">
              <recipe-tag-badge v-for="tag in selected" :key="tag.trackValue.toString()" small :tag="tag.option" />
            </template>
          </neb-select>

          <neb-select
            v-model="selectedMeals"
            placeholder="Filter by Meal"
            :options="filterData.meals"
            label-key="name"
            track-by-key="id"
            :transform-fun="transformId"
            use-only-tracked-key
            multiple
            leading-icon="material-symbols:restaurant-rounded"
          >
            <template #option="{ option }">
              <meal-badge :meal="option" />
            </template>

            <template #selection="{ selected }">
              <meal-badge v-for="meal in selected" :key="meal.trackValue.toString()" small :meal="meal.option" />
            </template>
          </neb-select>

          <neb-select
            v-model="selectedIngredients"
            placeholder="Filter by Ingredient"
            :options="filterData.ingredients"
            label-key="name"
            track-by-key="id"
            :transform-fun="transformId"
            use-only-tracked-key
            multiple
            leading-icon="material-symbols:grocery"
          />
        </div>
      </div>

      <neb-loading-state v-if="status === 'pending' && !recipes.length" />

      <neb-error-state v-else-if="status === 'error'" title="Failed to load recipes" :description="error?.message">
        <neb-button @click="refresh">
          Retry
        </neb-button>
      </neb-error-state>

      <template v-else-if="!recipes.length">
        <neb-empty-state
          v-if="searchTerm"
          title="No recipes found"
          description="Try adjusting your search terms to find what you're looking for"
        />

        <neb-empty-state
          v-else
          icon="material-symbols:menu-book-2-outline-rounded"
          title="No recipes yet"
          description="Start building your recipe collection by adding your first recipe"
        >
          <neb-button type="primary" @click="$router.push('/recipe/create')">
            <icon name="material-symbols:add-rounded" />
            Add Your First Recipe
          </neb-button>
        </neb-empty-state>
      </template>

      <template v-else>
        <div class="recipe-grid">
          <recipe-card
            v-for="recipe in recipes"
            :key="recipe.id.id.toString()"
            :recipe
          />
        </div>

        <neb-button
          v-if="recipes.length < recipeCount!"
          ref="recipe-loader"
          :hidden="status !== 'pending'"
          type="secondary-neutral"
          disabled
          loading
        />
      </template>
    </div>
  </page-layout>
</template>

<style scoped>
.page-wrapper {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.search-filter-row {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.search-row {
  display: flex;
  gap: var(--space-2);
}

.filter-row {
  width: 100%;
  display: flex;
  gap: var(--space-4);
  flex-wrap: wrap;

  & > * {
    flex: 1;
  }
}

.recipe-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: var(--space-6);
}

@media (--tablet-viewport) {
  .filter-span {
    display: none;
  }

  .filter-row {
    flex-direction: column;
    flex-wrap: nowrap;
    gap: var(--space-2);
  }

  .recipe-grid {
    grid-template-columns: 1fr;
    gap: var(--space-4);
  }
}

@media (--mobile-lg-viewport) {
  .recipe-grid {
    gap: var(--space-3) !important;
  }
}
</style>
