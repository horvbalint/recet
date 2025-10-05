<script setup lang="ts">
import type { PreparedQuery, RecordId } from 'surrealdb'
import type { OutCuisine, OutIngredient, OutMeal, OutRecipeTag } from '~/db'

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

const searchTerm = ref('')
const selectedCuisines = ref<OutCuisine['id'][]>([])
const selectedTags = ref<OutRecipeTag['id'][]>([])
const selectedMeals = ref<OutMeal['id'][]>([])
const selectedIngredients = ref<OutIngredient['id'][]>([])

const showFilter = ref(false)
const conditionCount = computed(() => selectedCuisines.value.length + selectedTags.value.length + selectedMeals.value.length + selectedIngredients.value.length)

const { data: filterData, status: filterDataStatus, refresh: queryFilterData } = useAsyncData(async () => {
  const [cuisenes, tags, meals, ingredients] = await db.query<[OutCuisine[], OutRecipeTag[], OutMeal[], OutIngredient[]]>(surql`
    SELECT id, name, color, flag FROM cuisine ORDER BY name ASC;
    SELECT id, name, color, icon FROM recipe_tag ORDER BY name ASC;
    SELECT id, name, color FROM meal ORDER BY name ASC;
    SELECT id, name FROM ingredient ORDER BY name ASC;
  `)

  return { cuisenes, tags, meals, ingredients }
}, {
  immediate: false,
})

async function toggleFilter() {
  if (!showFilter.value && !filterData.value)
    await queryFilterData()

  showFilter.value = !showFilter.value
}

const openedAt = new Date()
function constructWhereClause(query: PreparedQuery) {
  query.append` WHERE household = type::thing(${currentHousehold.value!.id}) && craeted_at <= ${openedAt}`

  if (searchTerm.value)
    query.append` && name @@ ${searchTerm.value}`

  if (selectedCuisines.value.length)
    query.append` && cuisine IN ${selectedCuisines.value}`
  if (selectedTags.value.length)
    query.append` && tags.intersect(${selectedTags.value}).len() > 0`
  if (selectedMeals.value.length)
    query.append` && meal.intersect(${selectedMeals.value}).len() > 0`
  if (selectedIngredients.value.length)
    query.append` && ingredients.ingredient.intersect(${selectedIngredients.value}).len() > 0`

  return query
}

function constructCountQuery() {
  const query = surql`SELECT VALUE count() FROM ONLY recipe`
  constructWhereClause(query)
  query.append` GROUP ALL`

  return query
}

const recipesPerPage = isMobile.value ? 5 : 9
const pageIndex = ref(0)
function constructRecipeQuery() {
  const query = surql`
    SELECT
      id,
      name,
      created_at,
      image_blur_hash,
      cooking_time_minutes,
      author.{username},
      ingredients.len(),
      steps.len(),
      cuisine.{name, color, flag},
      tags.{name, color, icon},
      meal.{name, color}
  `

  if (searchTerm.value)
    query.append`,search::score(0) as score FROM recipe`
  else
    query.append`FROM recipe`

  if (searchTerm.value) {
    if (currentHousehold.value!.language === 'hu')
      query.append` WITH INDEX hungarian_search_name`
    else
      query.append` WITH INDEX english_search_name`
  }

  constructWhereClause(query)

  if (searchTerm.value)
    query.append` ORDER BY score, created_at DESC`
  else
    query.append` ORDER BY created_at DESC`

  query.append` LIMIT ${recipesPerPage} START ${pageIndex.value * recipesPerPage}`

  return query
}

const conditionWatchSources = [currentHousehold, searchTerm, selectedCuisines, selectedIngredients, selectedMeals, selectedTags]
const { data, status, error, refresh } = useAsyncData('recipes', async () => {
  const recipeQuery = constructRecipeQuery()
  const countQuery = constructCountQuery()

  const [[recipes], [count]] = await Promise.all([
    db.query<[Recipe[]]>(recipeQuery),
    db.query<[{ count: number } | null]>(countQuery),
  ])

  return { recipeChunks: recipes, recipeCount: count?.count || 0 }
}, { watch: [...conditionWatchSources, pageIndex] })

const recipes = ref<Recipe[]>([])
watch(data, () => recipes.value.push(...data.value?.recipeChunks || []))

watch(conditionWatchSources, () => {
  pageIndex.value = 0
  recipes.value = []
}, {
  flush: 'sync',
})

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
            no-search
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
            no-search
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
            no-search
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
            :recipe="recipe"
          />
        </div>

        <neb-button
          v-if="recipes.length < data!.recipeCount"
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
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
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
