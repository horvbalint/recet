<script setup lang="ts">
definePageMeta({
  layout: 'app',
})

interface Recipe {
  id: string
  name: string
  description?: string
  ingredients: Array<{
    ingredient: string
    amount: string
    unit?: string
  }>
  steps: string[]
  author: {
    username: string
  }
  cuisine?: {
    name: string
    color: string
    flag?: string
  }
  tags?: Array<{
    name: string
    color: string
    icon?: string
  }>
  meal?: Array<{
    name: string
    color: string
  }>
  created_at: string
  updated_at: string
}

const route = useRoute()
const recipeId = route.params.id as string

const { data: recipe, status, error, refresh } = await useAsyncData<Recipe | null>(`recipe-${recipeId}`, async () => {
  const [result] = await db.query<[Recipe]>(surql`
    SELECT
      *,
      author.{username},
      cuisine.{name, color, flag},
      tags.{name, color, icon},
      meal.{name, color},
      ingredients.map(|$i| {
          amount: $i.amount,
          ingredient: $i.ingredient.name,
          unit: $i.unit.name
      })
    FROM ONLY
      type::thing('recipe', ${recipeId})
  `)

  return result
})

watch(currentHousehold, async () => await navigateTo('/'))
</script>

<template>
  <div class="recipe-detail">
    <neb-state-content :status :refresh error-title="Failed to load recipe" :error-description="error?.message">
      <neb-empty-state
        v-if="!recipe"
        icon="material-symbols:menu-book-2-outline-rounded"
        title="Recipe not found"
        description="The recipe you're looking for doesn't exist or has been removed"
      >
        <neb-button @click="$router.push('/')">
          <icon name="material-symbols:arrow-back-rounded" />
          Back to Recipes
        </neb-button>
      </neb-empty-state>

      <div v-else class="recipe-container">
        <header class="recipe-header">
          <div class="recipe-hero">
            <div class="recipe-image">
              <div class="image-placeholder">
                <icon name="material-symbols:restaurant-rounded" />
              </div>

              <div v-if="recipe.cuisine" class="cuisine-badge">
                <neb-badge :style="{ background: `${recipe.cuisine.color}20`, color: recipe.cuisine.color }">
                  <span v-if="recipe.cuisine.flag">{{ recipe.cuisine.flag }}</span>
                  {{ recipe.cuisine.name }}
                </neb-badge>
              </div>
            </div>

            <div class="recipe-info">
              <h1 class="recipe-title">
                {{ recipe.name }}
              </h1>

              <p v-if="recipe.description" class="recipe-description">
                {{ recipe.description }}
              </p>

              <div class="recipe-meta">
                <div class="meta-item">
                  <icon name="material-symbols:inventory-2-outline-rounded" />
                  <span>{{ recipe.ingredients?.length || 0 }} ingredients</span>
                </div>

                <div class="meta-item">
                  <icon name="material-symbols:format-list-numbered-rounded" />
                  <span>{{ recipe.steps?.length || 0 }} steps</span>
                </div>
              </div>

              <div class="recipe-author">
                <neb-avatar-card
                  :avatar="{ text: recipe.author?.username?.[0]?.toUpperCase() || '?', size: '40px' }"
                  :title="`By ${recipe.author?.username || 'Unknown'}`"
                  :text="`Created on ${new Date(recipe.created_at).toLocaleDateString()}`"
                />
              </div>

              <div v-if="recipe.tags?.length" class="recipe-tags">
                <neb-tag
                  v-for="tag in recipe.tags"
                  :key="tag.name"
                  :style="{ background: `${tag.color}20`, color: tag.color }"
                >
                  {{ tag.icon }}
                  {{ tag.name }}
                </neb-tag>
              </div>

              <div v-if="recipe.meal?.length" class="meal-types">
                <neb-badge
                  v-for="meal in recipe.meal"
                  :key="meal.name"
                  :style="{ background: `${meal.color}20`, color: meal.color }"
                >
                  {{ meal.name }}
                </neb-badge>
              </div>
            </div>
          </div>
        </header>

        <main class="recipe-content">
          <section class="ingredients-section">
            <h2>Ingredients</h2>
            <div v-if="recipe.ingredients?.length" class="ingredients-list">
              <div
                v-for="(ingredient, index) in recipe.ingredients"
                :key="index"
                class="ingredient-item"
              >
                <div class="ingredient-checkbox">
                  <neb-checkbox />
                </div>
                <div class="ingredient-details">
                  <span class="ingredient-amount">{{ ingredient.amount }}</span>
                  <span v-if="ingredient.unit" class="ingredient-unit">{{ ingredient.unit }}</span>
                  <span class="ingredient-name">{{ ingredient.ingredient }}</span>
                </div>
              </div>
            </div>
            <p v-else class="empty-message">
              No ingredients listed for this recipe.
            </p>
          </section>

          <section class="instructions-section">
            <h2>Instructions</h2>
            <div v-if="recipe.steps?.length" class="steps-list">
              <div
                v-for="(step, index) in recipe.steps"
                :key="index"
                class="step-item"
              >
                <div class="step-number">
                  {{ index + 1 }}
                </div>
                <div class="step-content">
                  <p class="step-description">
                    {{ step }}
                  </p>
                </div>
              </div>
            </div>
            <p v-else class="empty-message">
              No instructions provided for this recipe.
            </p>
          </section>
        </main>
      </div>
    </neb-state-content>
  </div>
</template>

<style scoped>
.recipe-detail {
  min-height: 100vh;
  background: var(--neutral-color-25);
}

.recipe-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: var(--space-6);
}

.header-navigation {
  margin-bottom: var(--space-6);
}

.recipe-hero {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-8);
  margin-bottom: var(--space-8);
}

.recipe-image {
  position: relative;
  height: 400px;
  border-radius: var(--radius-large);
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
  font-size: 64px !important;
  color: var(--neutral-color-400);
}

.cuisine-badge {
  position: absolute;
  top: var(--space-4);
  right: var(--space-4);
}

.recipe-info {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.recipe-title {
  font-size: var(--title-lg);
  font-weight: 700;
  color: var(--neutral-color-900);
  margin: 0;
  line-height: 1.2;
}

.recipe-description {
  font-size: var(--text-lg);
  color: var(--neutral-color-600);
  line-height: 1.5;
  margin: 0;
}

.recipe-meta {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-6);
}

.meta-item {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-md);
  color: var(--neutral-color-700);
  font-weight: 500;
}

.meta-item .icon {
  font-size: 20px !important;
  color: var(--neutral-color-500);
}

.time-breakdown {
  display: flex;
  gap: var(--space-6);
  padding: var(--space-4);
  background: var(--neutral-color-50);
  border-radius: var(--radius-default);
  border: 1px solid var(--neutral-color-200);
}

.time-item {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.time-label {
  font-size: var(--text-sm);
  color: var(--neutral-color-600);
  font-weight: 500;
}

.time-value {
  font-size: var(--text-lg);
  color: var(--neutral-color-900);
  font-weight: 600;
}

.recipe-author {
  padding: var(--space-4);
  background: var(--neutral-color-50);
  border-radius: var(--radius-default);
  border: 1px solid var(--neutral-color-200);
}

.recipe-tags {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.meal-types {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.recipe-content {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-8);
}

.ingredients-section,
.instructions-section {
  background: #fff;
  border-radius: var(--radius-large);
  padding: var(--space-6);
  box-shadow: var(--shadow-sm);
  border: 1px solid var(--neutral-color-100);
}

.ingredients-section h2,
.instructions-section h2 {
  font-size: var(--title-sm);
  font-weight: 600;
  color: var(--neutral-color-900);
  margin: 0 0 var(--space-5) 0;
  padding-bottom: var(--space-3);
  border-bottom: 2px solid var(--neutral-color-100);
}

.ingredients-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.ingredient-item {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3);
  border: 1px solid var(--neutral-color-100);
  border-radius: var(--radius-default);
  transition: all var(--duration-default);
}

.ingredient-item:hover {
  background: var(--neutral-color-25);
  border-color: var(--neutral-color-200);
}

.ingredient-details {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex: 1;
}

.ingredient-amount {
  font-weight: 600;
  color: var(--neutral-color-900);
  min-width: 50px;
}

.ingredient-unit {
  color: var(--neutral-color-600);
  font-size: var(--text-sm);
}

.ingredient-name {
  color: var(--neutral-color-700);
  flex: 1;
}

.steps-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.step-item {
  display: flex;
  gap: var(--space-4);
  padding: var(--space-4);
  border: 1px solid var(--neutral-color-100);
  border-radius: var(--radius-default);
}

.step-number {
  min-width: 40px;
  height: 40px;
  background: var(--primary-color);
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: var(--text-lg);
  flex-shrink: 0;
}

.step-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.step-description {
  color: var(--neutral-color-700);
  line-height: 1.6;
  margin: 0;
}

.empty-message {
  color: var(--neutral-color-500);
  font-style: italic;
  text-align: center;
  padding: var(--space-8);
}

/* Responsive Design */
@media (--tablet-viewport) {
  .recipe-container {
    padding: var(--space-4);
  }

  .recipe-hero {
    grid-template-columns: 1fr;
    gap: var(--space-6);
  }

  .recipe-image {
    height: 300px;
  }

  .recipe-content {
    grid-template-columns: 1fr;
    gap: var(--space-6);
  }

  .ingredients-section,
  .instructions-section {
    padding: var(--space-4);
  }
}

@media (--mobile-lg-viewport) {
  .recipe-container {
    padding: 0;
  }

  .recipe-hero {
    gap: var(--space-4);
  }

  .recipe-image {
    height: 250px;
  }

  .recipe-title {
    font-size: var(--title-md);
  }

  .recipe-meta {
    gap: var(--space-4);
  }

  .meta-item {
    font-size: var(--text-sm);
  }

  .time-breakdown {
    flex-direction: column;
    gap: var(--space-3);
  }

  .ingredients-section,
  .instructions-section {
    padding: var(--space-3);
  }

  .ingredient-item {
    padding: var(--space-2);
  }

  .step-item {
    padding: var(--space-3);
    gap: var(--space-3);
  }

  .step-number {
    min-width: 32px;
    height: 32px;
    font-size: var(--text-md);
  }
}

/* Dark Mode */
.dark-mode {
  .recipe-detail {
    background: var(--neutral-color-950);
  }

  .recipe-title {
    color: var(--neutral-color-100);
  }

  .recipe-description {
    color: var(--neutral-color-400);
  }

  .meta-item {
    color: var(--neutral-color-300);
  }

  .time-breakdown,
  .recipe-author {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);
  }

  .time-label {
    color: var(--neutral-color-400);
  }

  .time-value {
    color: var(--neutral-color-200);
  }

  .ingredients-section,
  .instructions-section {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);
  }

  .ingredients-section h2,
  .instructions-section h2 {
    color: var(--neutral-color-200);
    border-color: var(--neutral-color-800);
  }

  .ingredient-item {
    border-color: var(--neutral-color-800);
  }

  .ingredient-item:hover {
    background: var(--neutral-color-800);
    border-color: var(--neutral-color-700);
  }

  .ingredient-amount {
    color: var(--neutral-color-200);
  }

  .ingredient-unit {
    color: var(--neutral-color-400);
  }

  .ingredient-name {
    color: var(--neutral-color-300);
  }

  .step-item {
    border-color: var(--neutral-color-800);
  }

  .step-description {
    color: var(--neutral-color-300);
  }

  .image-placeholder {
    background: linear-gradient(135deg, var(--neutral-color-800), var(--neutral-color-900));
  }
}
</style>
