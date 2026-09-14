<script setup lang="ts">
import type { RecordId } from 'surrealdb'

export interface Recipe {
  id: RecordId<'recipe'>
  name: string
  ingredients: number
  recipes: number
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
  public: boolean
  subrecipe_only: boolean
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
    searchTerm,
    conditions: filterConditions,
    showSubrecipes,
  },
} = useRecipeState()

const conditionCount = useConditionCount(filterConditions)
const activeFilterCount = computed(() => conditionCount.value + (showSubrecipes.value ? 1 : 0))
const showFilter = ref(!!activeFilterCount.value)

const { data: filterData, status: filterStatus, refresh: queryFilterData } = useFilterData()
if (showFilter.value)
  queryFilterData()

async function toggleFilter() {
  if (!showFilter.value)
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
        :title="$t('recipes.list.title')"
        :description="$t('recipes.list.description')"
        :type="pageHeaderType"
        has-separator
      >
        <template v-if="recipes.length && isCurrHouseholdEditor" #actions>
          <neb-button small type="primary" @click="$router.push('/recipe/create')">
            <icon name="material-symbols:add-rounded" />
            {{ $t('recipes.list.addButton') }}
          </neb-button>
        </template>
      </neb-content-header>
    </template>

    <div class="page-wrapper">
      <div class="search-filter-row">
        <div class="search-row">
          <neb-search-input v-model="searchTerm" lazy />

          <neb-button
            type="secondary"
            :intent="activeFilterCount ? 'primary' : 'neutral'"
            :disabled="filterStatus === 'pending'"
            :loading="filterStatus === 'pending'"
            small
            @click="toggleFilter()"
          >
            <icon name="material-symbols:filter-list-rounded" />
            <span class="filter-span">{{ $t('recipes.list.filters') }}</span>
            <span v-if="activeFilterCount">({{ activeFilterCount }})</span>
          </neb-button>
        </div>

        <div v-neb-expand="showFilter" class="filter-row">
          <recipe-filter
            v-model="filterConditions"
            :filter-data="filterData"
          >
            <template #extra-options>
              <neb-toggle v-model="showSubrecipes" size="small" :label="$t('recipes.list.showSubrecipes')" />
            </template>
          </recipe-filter>
        </div>
      </div>

      <neb-loading-state v-if="status === 'pending' && !recipes.length" />

      <neb-error-state v-else-if="status === 'error'" :title="$t('recipes.list.error.title')" :description="error?.message">
        <neb-button @click="refresh">
          {{ $t('common.retry') }}
        </neb-button>
      </neb-error-state>

      <template v-else-if="!recipes.length">
        <neb-empty-state
          v-if="searchTerm"
          :title="$t('recipes.list.empty.noResults.title')"
          :description="$t('recipes.list.empty.noResults.description')"
        />

        <neb-empty-state
          v-else
          icon="material-symbols:menu-book-2-outline-rounded"
          :title="$t('recipes.list.empty.noData.title')"
          :description="$t('recipes.list.empty.noData.description')"
        >
          <neb-button type="primary" @click="$router.push('/recipe/create')">
            <icon name="material-symbols:add-rounded" />
            {{ $t('recipes.list.addFirstButton') }}
          </neb-button>
        </neb-empty-state>
      </template>

      <template v-else>
        <div class="recipe-grid">
          <recipe-card
            v-for="recipe in recipes"
            :key="recipe.id.id.toString()"
            :recipe="recipe"
          />
        </div>

        <neb-button
          v-if="recipes.length < recipeCount!"
          ref="recipe-loader"
          :hidden="status !== 'pending'"
          type="secondary"
          intent="neutral"
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
