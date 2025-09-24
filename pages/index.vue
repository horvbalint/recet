<script setup lang="ts">
import type { RecordId } from 'surrealdb'

interface Recipe {
  id: RecordId
  name: string
  ingredients: number
  steps: number
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

function constructQuery() {
  const baseQuery = surql`
    SELECT
      id,
      name,
      ingredients.len(),
      steps.len(),
      author.{username},
      cuisine.{name, color, flag},
      tags.{name, color, icon},
      meal.{name, color},
      created_at
  `

  if (searchTerm.value)
    baseQuery.append`,search::score(0) as score FROM recipe`
  else
    baseQuery.append`FROM recipe`

  if (searchTerm.value) {
    if (currentHousehold.value!.language === 'hu')
      baseQuery.append` WITH INDEX hungarian_search_name`
    else
      baseQuery.append` WITH INDEX english_search_name`
  }

  if (searchTerm.value) {
    return baseQuery.append`
      WHERE
        household = type::thing(${currentHousehold.value!.id}) && name @@ ${searchTerm.value}
      ORDER BY
        score, created_at DESC
    `
  }
  else {
    return baseQuery.append`
      WHERE
        household = type::thing(${currentHousehold.value!.id})
      ORDER BY
        created_at DESC
    `
  }
}

const { data: recipes, status, error, refresh } = await useAsyncData<Recipe[]>('recipes', async () => {
  const query = constructQuery()
  const decoder = new TextDecoder()
  console.log(decoder.decode(query.query.encoded))
  const [result] = await db.query<[Recipe[]]>(query)

  return result
}, { watch: [currentHousehold, searchTerm] })
</script>

<template>
  <nuxt-layout name="app">
    <template #content-header>
      <neb-content-header
        title="Recipes"
        description="Discover and explore delicious recipes from our collection"
        :type="pageHeaderType"
        has-separator
      >
        <template v-if="recipes?.length" #actions>
          <neb-button small type="primary" @click="$router.push('/recipe/create')">
            <icon name="material-symbols:add-rounded" />
            Add Recipe
          </neb-button>
        </template>
      </neb-content-header>
    </template>

    <div class="page-wrapper">
      <neb-search-input v-model="searchTerm" lazy />

      <neb-state-content :status :refresh error-title="Failed to load recipes" :error-description="error?.message">
        <template v-if="!recipes?.length">
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

        <div v-else class="recipe-grid">
          <recipe-card
            v-for="recipe in recipes"
            :key="recipe.id.id.toString()"
            :recipe="recipe"
          />
        </div>
      </neb-state-content>
    </div>
  </nuxt-layout>
</template>

<style scoped>
.page-wrapper {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.recipe-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: var(--space-6);
}

@media (--tablet-viewport) {
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
