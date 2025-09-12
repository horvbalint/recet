<script setup lang="ts">
import type { RecordId } from "surrealdb";

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

const { data: recipes, status, error, refresh } = await useAsyncData<Recipe[]>('recipes', async () => {
  const [result] = await db.query<[Recipe[]]>(surql`
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
    FROM
      recipe
    ORDER BY
      created_at DESC
    FETCH
      author, cuisine, tags, meal
  `)

  return result
})
</script>

<template>
  <div class="recipe-index">
    <neb-content-header
      title="Recipes"
      description="Discover and explore delicious recipes from our collection"
      type="page"
      has-separator
    >
      <template #actions>
          <neb-button type="secondary" @click="$router.push('/masterData')">
            <icon name="material-symbols:settings" />
            Master Data
          </neb-button>
          <neb-button type="primary" @click="$router.push('/recipe/create')">
            <icon name="material-symbols:add-rounded" />
            Add Recipe
          </neb-button>
      </template>
    </neb-content-header>

    <main class="main-content">
      <neb-state-content :status :refresh error-title="Failed to load recipes" :error-description="error?.message">
        <neb-empty-state 
          v-if="!recipes?.length"
          icon="material-symbols:restaurant-menu-rounded"
          title="No recipes yet"
          description="Start building your recipe collection by adding your first recipe"
        >
          <neb-button type="primary" @click="$router.push('/recipe/create')">
            <icon name="material-symbols:add-rounded" />
            Add Your First Recipe
          </neb-button>
        </neb-empty-state>
        
        <div v-else class="recipe-grid">
          <recipe-card 
            v-for="recipe in recipes" 
            :key="recipe.id.id.toString()" 
            :recipe="recipe"
          />
        </div>
      </neb-state-content>
    </main>
  </div>
</template>

<style scoped>
.recipe-index {
  min-height: 100vh;
  background: var(--neutral-color-25);
  padding: var(--space-6);
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding-top: var(--space-6);
}

.recipe-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: var(--space-6);
}

@media (--tablet-viewport) {
  .recipe-index {
    padding: var(--space-4);
  }

  .main-content {
    padding-top: var(--space-4);
  }

  .recipe-grid {
    grid-template-columns: 1fr;
    gap: var(--space-4);
  }
}

@media (--mobile-lg-viewport) {
  .recipe-index {
    padding: var(--space-3) !important;
  }

  .main-content {
    padding-top: var(--space-3) !important;
  }

  .recipe-grid {
    gap: var(--space-3) !important;
  }
}

.dark-mode {
  .recipe-index {
    background: var(--neutral-color-950);
  }
}
</style>