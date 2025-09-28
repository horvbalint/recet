<script setup lang="ts">
import type { RecordId } from 'surrealdb'

definePageMeta({
  layout: 'app',
})

interface Recipe {
  id: RecordId<'recipe'>
  name: string
  image_blur_hash?: string
  ingredients: Array<{
    ingredient: string
    amount: string
    unit?: string
    description?: string
    skip_from_shopping_list: boolean
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
}

const route = useRoute()
const recipeId = route.params.id as string

const { data: queriedRecipe, status: queryStatus, error, refresh } = useAsyncData<Recipe | null>(`recipe-${recipeId}`, async () => {
  const [result] = await db.query<[Recipe]>(surql`
    SELECT
      id,
      name,
      steps,
      created_at,
      image_blur_hash,
      author.{username},
      cuisine.{name, color, flag},
      tags.{name, color, icon},
      meal.{name, color},
      ingredients.map(|$i| {
        amount: $i.amount,
        ingredient: $i.ingredient.name,
        unit: $i.unit.name,
        description: $i.description,
        skip_from_shopping_list: $i.ingredient.skip_from_shopping_list
      })
    FROM ONLY
      type::thing('recipe', ${recipeId})
  `)

  return result
})

const recipe = computed<Recipe | null | undefined>(() => {
  const cachedRecipe = getCachedRecipe(recipeId)
  if (!cachedRecipe || queriedRecipe.value)
    return queriedRecipe.value

  return {
    ...cachedRecipe,
    ingredients: [],
    steps: [],
  }
})

const status = computed(() => {
  if (queryStatus.value === 'pending' && recipe.value)
    return 'success'
  else
    return queryStatus.value
})

const { data: shoppingLists, error: shoppingListError } = useAsyncData('shopping-lists-for-recipe', async () => {
  if (!currentHousehold.value)
    return []

  const [lists] = await db.query<[{ id: RecordId<'shopping_list'>, name: string }[]]>(surql`
    SELECT id, name, updated_at FROM shopping_list 
    WHERE household = ${currentHousehold.value.id}
    ORDER BY updated_at DESC
  `)

  return lists
}, { watch: [currentHousehold] })

logOnError(shoppingListError)

const shoppingListMenuItems = computed(() => {
  if (!shoppingLists.value?.length)
    return []

  return shoppingLists.value.map(list => ({
    text: list.name,
    icon: 'material-symbols:shopping-cart-outline-rounded',
    callback: () => addToShoppingList(list.id),
  }))
})

const isAddingToList = ref(false)

const checkedIngredients = ref<number[]>([])
async function addToShoppingList(shoppingListId: RecordId<'shopping_list'>) {
  try {
    isAddingToList.value = true

    const checkedIngredientIndexes = checkedIngredients.value.length
      ? checkedIngredients.value
      : recipe.value!.ingredients!.map((_, index) => index)

    const ingredientIndexesToAdd = checkedIngredientIndexes.filter(index => !recipe.value!.ingredients[index]!.skip_from_shopping_list)

    await db.query(surql`
      fn::add_recipe_ingredients_to_shopping_list(
        ${recipe.value!.id},
        ${ingredientIndexesToAdd},
        ${shoppingListId},
      )
    `)

    checkedIngredients.value = []

    useNebToast({ type: 'success', title: 'Ingredients added', description: `Added ${ingredientIndexesToAdd.length} ingredients to the shopping list.` })
  }
  catch (err) {
    console.error('Error adding ingredients to shopping list:', err)
    useNebToast({ type: 'error', title: 'Failed to add ingredients', description: 'Could not add ingredients to shopping list.' })
  }
  finally {
    isAddingToList.value = false
  }
}

const inProgress = ref(false)
async function deleteRecipe() {
  try {
    const confirmed = await useNebConfirm({ title: 'Confirm action!', description: 'Are you sure you want to delete this recipe? This action cannot be undone.' })
    if (!confirmed)
      return

    inProgress.value = true

    await db.query(surql`DELETE type::thing('recipe', ${recipeId})`)
    useNebToast({ type: 'success', title: 'Recipe deleted!', description: 'The recipe has been deleted successfully.' })
    await navigateTo('/')
  }
  catch (err) {
    console.error('Error deleting recipe:', err)
    useNebToast({ type: 'error', title: 'Failed to delete recipe!', description: 'Could not delete the recipe. Please try again.' })
  }
  finally {
    inProgress.value = false
  }
}

async function editRecipe() {
  await navigateTo(`/recipe/create/${recipeId}`)
}

const viewTransitions = getRecipeViewTransitionNames(recipeId)

watch(currentHousehold, async () => await navigateTo('/'))
</script>

<template>
  <page-layout>
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
          <header>
            <div class="recipe-hero">
              <recipe-image class="recipe-image" :recipe :width-px="600" :height-px="400">
                <div class="recipe-actions">
                  <neb-button type="secondary-neutral" small :disabled="inProgress" :loading="inProgress" @click="editRecipe()">
                    <icon name="material-symbols:edit-outline-rounded" />
                  </neb-button>

                  <neb-button type="secondary-neutral" small :disabled="inProgress" :loading="inProgress" @click="deleteRecipe()">
                    <icon name="material-symbols:delete-outline-rounded" />
                  </neb-button>
                </div>
              </recipe-image>

              <div class="recipe-info">
                <neb-content-header
                  type="page"
                  :title="recipe.name"
                />

                <div class="recipe-meta">
                  <div class="meta-item">
                    <icon name="material-symbols:grocery" />
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
                  <badge-tag v-for="tag in recipe.tags" :key="tag.name" :tag />
                </div>

                <div v-if="recipe.meal?.length" class="meal-types">
                  <badge-meal v-for="meal in recipe.meal" :key="meal.name" :meal />
                </div>
              </div>
            </div>
          </header>

          <neb-state-content :status="queryStatus" :refresh :error-description="error?.message">
            <main class="recipe-content">
              <section class="ingredients-section">
                <neb-content-header
                  title="Ingredients"
                  type="page"
                  has-separator
                >
                  <template #actions>
                    <neb-menu v-if="recipe.ingredients?.length && shoppingListMenuItems.length" :menus="shoppingListMenuItems" :floating-options="{ placement: 'bottom-end' }">
                      <template #trigger="{ toggle }">
                        <neb-button type="secondary" small :loading="isAddingToList" @click="toggle()">
                          <icon name="material-symbols:add-shopping-cart-rounded" />
                          Add to Shopping List
                          <template v-if="checkedIngredients.length">
                            ({{ checkedIngredients.length }})
                          </template>
                        </neb-button>
                      </template>
                    </neb-menu>
                  </template>
                </neb-content-header>

                <div v-if="recipe.ingredients?.length" class="ingredients-list">
                  <div
                    v-for="(ingredient, index) in recipe.ingredients"
                    :key="index"
                    class="ingredient-item"
                    @click="($refs.ingredientCheckbox as any)[index].handleClick()"
                  >
                    <div class="ingredient-checkbox">
                      <neb-checkbox ref="ingredientCheckbox" v-model="checkedIngredients" :value="index" @click.stop />
                    </div>

                    <div class="ingredient-content">
                      <div class="ingredient-details">
                        <span class="ingredient-amount">{{ ingredient.amount }}</span>
                        <span v-if="ingredient.unit" class="ingredient-unit">{{ ingredient.unit }}</span>
                        <span class="ingredient-name">{{ ingredient.ingredient }}</span>
                      </div>

                      <div v-if="ingredient.description" class="ingredient-description">
                        {{ ingredient.description }}
                      </div>
                    </div>

                    <neb-tooltip
                      v-if="ingredient.skip_from_shopping_list"
                      title="This ingredient will be skipped from being added to shopping lists"
                    >
                      <icon name="material-symbols:receipt-long-off-outline-rounded" />
                    </neb-tooltip>
                  </div>
                </div>

                <p v-else class="empty-message">
                  No ingredients listed for this recipe.
                </p>
              </section>

              <section class="instructions-section">
                <neb-content-header
                  title="Instructions"
                  type="page"
                  has-separator
                />
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
          </neb-state-content>
        </div>
      </neb-state-content>
    </div>
  </page-layout>
</template>

<style scoped>
.recipe-detail {
  min-height: 100vh;
  background: var(--neutral-color-25);
  border-radius: var(--radius-large);
  view-transition-name: v-bind('viewTransitions.container');
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
  border-radius: var(--radius-large);
  border: 1px solid var(--neutral-color-200);

  .recipe-actions {
    position: absolute;
    top: var(--space-4);
    left: var(--space-4);
    display: flex;
    gap: var(--space-1);

    .icon {
      font-size: 20px !important;
      margin: -4px;
    }
  }
}

.recipe-header-right {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: flex-end;
}

.recipe-info {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: var(--space-4);

  :deep(.neb-content-header) {
    h1 {
      view-transition-name: v-bind('viewTransitions.name');
    }
  }
}

.recipe-meta {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-6);
  width: fit-content;
  view-transition-name: v-bind('viewTransitions.meta');
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

.recipe-author {
  margin-top: var(--space-2);
}

.recipe-tags {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  view-transition-name: v-bind('viewTransitions.tags');
  width: fit-content;
}

.meal-types {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  width: fit-content;
  view-transition-name: v-bind('viewTransitions.mealTypes');
}

.recipe-content {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-8);
}

.ingredients-section,
.instructions-section {
  background: #fff;
  border: 1px solid var(--neutral-color-200);
  border-radius: var(--radius-large);
  padding: var(--space-6);
  margin-bottom: var(--space-6);
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
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

  .icon {
    font-size: 20px !important;
    color: var(--neutral-color-400);

    &:hover {
      color: var(--neutral-color-600);
    }
  }
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

.ingredient-content {
  display: flex;
  flex-direction: column;
  flex: 1;
  gap: var(--space-1);
}

.ingredient-amount {
  font-weight: 600;
  color: var(--neutral-color-900);
}

.ingredient-unit {
  color: var(--neutral-color-600);
  font-size: var(--text-sm);
}

.ingredient-name {
  color: var(--neutral-color-700);
  flex: 1;
}

.ingredient-description {
  color: var(--neutral-color-500);
  font-size: var(--text-sm);
  font-style: italic;
}

.steps-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.step-item {
  display: flex;
  gap: var(--space-4);
  padding: var(--space-4);
  border: 1px solid var(--neutral-color-100);
  border-radius: var(--radius-default);
}

.step-number {
  flex-shrink: 0;
  width: 40px;
  height: 40px;
  background: linear-gradient(135deg, var(--primary-color-500), var(--primary-color-400));
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: var(--text-lg);
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
  .recipe-content {
    grid-template-columns: 1fr;
    gap: var(--space-6);
  }

  .recipe-container {
    padding: 0;
  }

  .recipe-hero {
    grid-template-columns: 1fr;
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
    width: 32px;
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

  .meta-item {
    color: var(--neutral-color-300);
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

  .step-number {
    background: linear-gradient(135deg, var(--primary-color-600), var(--primary-color-700));
  }

  .step-description {
    color: var(--neutral-color-300);
  }

  .recipe-image {
    border: 1px solid var(--neutral-color-700);
  }
}
</style>
