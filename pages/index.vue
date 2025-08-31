<script setup lang="ts">
import Surreal from "surrealdb";
import { surql } from "surrealdb";
import dayjs from "dayjs";

interface Recipe {
  id: string
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

const db = new Surreal();

// Connect to the database
await db.connect("http://localhost:8000/rpc");

// Signin as a namespace, database, or root user
await db.signin({
    username: "root",
    password: "root",
});

// Select a specific namespace / database
await db.use({
    namespace: "recet",
    database: "recet"
});

// Fetch recipes with related data
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

  return JSON.parse(JSON.stringify(result))
})

function getEstimatedTime(stepCount: number) {
  if (stepCount <= 3) return "15-30 min"
  if (stepCount <= 6) return "30-45 min"
  if (stepCount <= 10) return "45-60 min"
  return "60+ min"
}
</script>

<template>
  <div class="recipe-index">
    <header class="page-header">
      <div class="header-content">
        <h1>Recipes</h1>
        <p>Discover and explore delicious recipes from our collection</p>
      </div>
      
      <div class="header-actions">
        <neb-button type="primary">
          <icon name="material-symbols:add-rounded" />
          Add Recipe
        </neb-button>
      </div>
    </header>

    <main class="main-content">
      <neb-state-content :status :refresh error-title="Failed to load recipes" :error-description="error?.message">
        <neb-empty-state 
          v-if="!recipes || recipes.length === 0"
          icon="material-symbols:restaurant-menu-rounded"
          title="No recipes yet"
          description="Start building your recipe collection by adding your first recipe"
        >
          <neb-button type="primary">
            <icon name="material-symbols:add-rounded" />
            Add Your First Recipe
          </neb-button>
        </neb-empty-state>
        
        <div v-else class="recipe-grid">
          <div 
            v-for="recipe in recipes" 
            :key="recipe.id" 
            class="recipe-card"
          >
            <div class="recipe-image">
              <div class="image-placeholder">
                <icon name="material-symbols:restaurant-rounded" />
              </div>
              
              <div v-if="recipe.cuisine" class="cuisine-badge">
                <neb-badge :style="{ background: recipe.cuisine.color + '20', color: recipe.cuisine.color }">
                  <span v-if="recipe.cuisine.flag">{{ recipe.cuisine.flag }}</span>
                  {{ recipe.cuisine.name }}
                </neb-badge>
              </div>
            </div>
            
            <div class="recipe-content">
              <div class="recipe-header">
                <h3 class="recipe-title">{{ recipe.name }}</h3>
                <neb-avatar-card
                  v-if="recipe.author"
                  :avatar="{ text: recipe.author?.username?.[0]?.toUpperCase() || '?', size: '32px' }"
                  :title="recipe.author?.username || 'Unknown'"
                  :text="dayjs(recipe.created_at).format('YYYY-MM-DD')"
                />
              </div>
              
              <div class="recipe-meta">
                <div class="meta-item">
                  <icon name="material-symbols:inventory-2-outline-rounded" />
                  <span>{{ recipe.ingredients }} ingredients</span>
                </div>
                
                <div class="meta-item">
                  <icon name="material-symbols:format-list-numbered-rounded" />
                  <span>{{ recipe.steps }} steps</span>
                </div>
                
                <div class="meta-item">
                  <icon name="material-symbols:schedule-outline-rounded" />
                  <span>{{ getEstimatedTime(recipe.steps) }}</span>
                </div>
              </div>
              
              <div v-if="recipe.tags && recipe.tags.length > 0" class="recipe-tags">
                <neb-tag
                  v-for="tag in recipe.tags" 
                  :key="tag.name"
                  :style="{ background: tag.color + '20', color: tag.color }"
                >
                  {{ tag.icon }}
                  {{ tag.name }}
                </neb-tag>
                
                <neb-badge v-if="recipe.tags.length > 3" small>
                  +{{ recipe.tags.length - 3 }} more
                </neb-badge>
              </div>
              
              <div v-if="recipe.meal && recipe.meal.length > 0" class="meal-types">
                <neb-badge 
                  v-for="meal in recipe.meal" 
                  :key="meal.name"
                  small
                  :style="{ background: meal.color + '20', color: meal.color }"
                >
                  {{ meal.name }}
                </neb-badge>
              </div>
            </div>
          </div>
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

.page-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-6);
  margin-bottom: var(--space-8);
  padding-bottom: var(--space-6);
  border-bottom: 1px solid var(--neutral-color-200);
}

.header-content {
  flex: 1;
}

.header-content h1 {
  font-size: var(--title-lg);
  font-weight: 700;
  color: var(--neutral-color-900);
  margin-bottom: var(--space-2);
}

.header-content p {
  font-size: var(--text-lg);
  color: var(--neutral-color-600);
  margin: 0;
}

.header-actions {
  display: flex;
  gap: var(--space-3);
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
}

.recipe-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: var(--space-6);
}

.recipe-card {
  background: #fff;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
  transition: all var(--duration-default);
  cursor: pointer;
  border: 1px solid var(--neutral-color-100);
}

.recipe-card:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
  border-color: var(--neutral-color-200);
}

.recipe-image {
  position: relative;
  height: 200px;
  overflow: hidden;
}

.image-placeholder {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, var(--neutral-color-100), var(--neutral-color-50));
  display: flex;
  align-items: center;
  justify-content: center;
}

.image-placeholder .icon {
  font-size: 48px !important;
  color: var(--neutral-color-400);
}

.cuisine-badge {
  position: absolute;
  top: var(--space-3);
  right: var(--space-3);
}

.recipe-content {
  padding: var(--space-5);
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.recipe-header {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.recipe-title {
  font-size: var(--text-xl);
  font-weight: 600;
  color: var(--neutral-color-900);
  margin: 0;
  line-height: 1.3;
}

.recipe-meta {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-4);
}

.meta-item {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-sm);
  color: var(--neutral-color-600);
  font-weight: 500;
}

.meta-item .icon {
  font-size: 18px !important;
  color: var(--neutral-color-500);
}

.recipe-tags {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  align-items: center;
}

.meal-types {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

@media (--tablet-viewport) {
  .recipe-index {
    padding: var(--space-4);
  }
  
  .page-header {
    flex-direction: column;
    align-items: flex-start;
    gap: var(--space-4);
  }
  
  .recipe-grid {
    grid-template-columns: 1fr;
    gap: var(--space-4);
  }
  
  .recipe-card {
    border-radius: var(--radius-default);
  }
  
  .recipe-image {
    height: 160px;
  }
}

@media (--mobile-viewport) {
  .recipe-index {
    padding: var(--space-3);
  }
  
  .recipe-content {
    padding: var(--space-4);
  }
  
  .recipe-meta {
    gap: var(--space-3);
  }
  
  .meta-item {
    font-size: var(--text-xs);
  }
}

.dark-mode {
  .recipe-index {
    background: var(--neutral-color-950);
  }
  
  .page-header {
    border-bottom-color: var(--neutral-color-800);
  }
  
  .header-content h1 {
    color: var(--neutral-color-100);
  }
  
  .header-content p {
    color: var(--neutral-color-400);
  }
  
  .recipe-card {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);
  }
  
  .recipe-card:hover {
    border-color: var(--neutral-color-700);
  }
  
  .recipe-title {
    color: var(--neutral-color-100);
  }
  
  .meta-item {
    color: var(--neutral-color-400);
  }
  
  .meta-item .icon {
    color: var(--neutral-color-500);
  }
  
  .image-placeholder {
    background: linear-gradient(135deg, var(--neutral-color-800), var(--neutral-color-900));
  }
}
</style>