<script setup lang="ts">
import type { Menu } from 'nebula/components/overlays/neb-menu.vue'
import type { RecordId } from 'surrealdb'

definePageMeta({
  layout: 'app',
})

onBeforeRouteLeave((to, _, next) => {
  if (to.path !== '/')
    return next()

  startTransitionThen(next)
})

interface Recipe {
  id: RecordId<'recipe'>
  name: string
  image_blur_hash?: string
  portions: number
  cooking_time_minutes?: number
  ingredients: Array<{
    ingredient: string
    amount: number
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
  const [result] = await db
    .query(surql`
      SELECT
        id,
        name,
        steps,
        created_at,
        image_blur_hash,
        portions,
        cooking_time_minutes,
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
        type::record('recipe', ${recipeId})
    `)
    .collect<[Recipe]>()

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

  const [lists] = await db
    .query(surql`
      SELECT id, name, updated_at FROM shopping_list 
      WHERE household = ${currentHousehold.value.id}
      ORDER BY updated_at DESC
    `)
    .collect<[{ id: RecordId<'shopping_list'>, name: string }[]]>()

  return lists
}, { watch: [currentHousehold] })

logOnError(shoppingListError)

const isAddingToList = ref(false)

const checkedIngredients = ref<number[]>([])
const portions = ref(recipe.value?.portions)
const portionRatio = computed(() => {
  if (!portions.value || !recipe.value?.portions)
    return 1

  return portions.value / recipe.value.portions
})

function decrementPortions() {
  if (portions.value! >= 2)
    portions.value! -= 1
}
function incrementPortions() {
  portions.value! += 1
}

watch(recipe, () => portions.value = recipe.value!.portions)

async function addToShoppingList(shoppingListId: RecordId<'shopping_list'>) {
  try {
    isAddingToList.value = true

    const checkedIngredientIndexes = checkedIngredients.value.length
      ? checkedIngredients.value
      : recipe.value!.ingredients!.map((_, index) => index)

    const ingredientIndexesToAdd = checkedIngredientIndexes.filter(index => !recipe.value!.ingredients[index]!.skip_from_shopping_list)

    await db
      .query(surql`
        fn::add_recipe_ingredients_to_shopping_list(
          ${recipe.value!.id},
          ${ingredientIndexesToAdd},
          ${shoppingListId},
          ${portionRatio.value}
        )
      `)
      .collect()

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

    await db
      .query(surql`DELETE type::record('recipe', ${recipeId})`)
      .collect()
    clearRecipeCache()

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

async function copyRecipe() {
  await navigateTo(`/recipe/create/${recipeId}?copy=true`)
}

const menus: Menu[] = [
  { text: 'Copy', icon: 'material-symbols:content-copy-outline-rounded', callback: copyRecipe },
  { text: 'Delete', icon: 'material-symbols:delete-outline-rounded', callback: deleteRecipe, segment: true, desctructive: true },
]

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

        <template v-else>
          <header>
            <div class="recipe-hero">
              <recipe-image class="recipe-image" :recipe :width-px="600" :height-px="400">
                <div class="recipe-actions">
                  <neb-button type="secondary-neutral" small :disabled="inProgress" :loading="inProgress" @click="editRecipe()">
                    <icon name="material-symbols:edit-outline-rounded" />
                  </neb-button>

                  <neb-menu small :menus>
                    <template #trigger="{ toggle }">
                      <neb-button type="secondary-neutral" small :disabled="inProgress" :loading="inProgress" @click="toggle()">
                        <icon name="material-symbols:more-horiz" />
                      </neb-button>
                    </template>
                  </neb-menu>
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

                  <div v-if="recipe.cooking_time_minutes" class="meta-item">
                    <icon name="material-symbols:schedule-outline-rounded" />
                    <span>{{ recipe.cooking_time_minutes }} min</span>
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
                  <recipe-tag-badge v-for="tag in recipe.tags" :key="tag.name" :tag />
                </div>

                <div v-if="recipe.meal?.length" class="meal-types">
                  <meal-badge v-for="meal in recipe.meal" :key="meal.name" :meal />
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
                    <neb-dropdown :floating-options="{ placement: 'bottom-end' }">
                      <template #trigger="{ toggle }">
                        <neb-button type="tertiary-neutral" small :disabled="isAddingToList" :loading="isAddingToList" @click="toggle()">
                          <icon name="material-symbols:more-vert" />
                        </neb-button>
                      </template>

                      <template #content="{ close }">
                        <div class="ingredients-dropdown">
                          <neb-content-header v-if="portions" title="Portions:" type="paragraph" has-separator>
                            <template #actions>
                              <div class="portion-controls">
                                <neb-button small square type="tertiary-neutral" @click="decrementPortions()">
                                  <icon name="material-symbols:remove-rounded" />
                                </neb-button>

                                {{ portions }}

                                <neb-button small square type="tertiary-neutral" @click="incrementPortions()">
                                  <icon name="material-symbols:add-rounded" />
                                </neb-button>
                              </div>
                            </template>
                          </neb-content-header>

                          <div class="add-to-list-wrapper">
                            <neb-content-header
                              :title="checkedIngredients.length ? `Add to shopping list (${checkedIngredients.length}):` : 'Add to shopping list:'"
                              type="paragraph"
                            />

                            <div class="list-buttons">
                              <neb-button
                                v-for="list in shoppingLists!"
                                :key="list.id.id.toString()"
                                small
                                type="tertiary-neutral"
                                full-width
                                @click="addToShoppingList(list.id); close()"
                              >
                                <icon name="material-symbols:shopping-cart-outline-rounded" />
                                <span>{{ list.name }}</span>
                              </neb-button>
                            </div>
                          </div>
                        </div>
                      </template>
                    </neb-dropdown>
                  </template>
                </neb-content-header>

                <div v-if="recipe.ingredients?.length" class="ingredients-list">
                  <neb-checkbox
                    v-for="(ingredient, index) in recipe.ingredients"
                    :key="index"
                    v-model="checkedIngredients"
                    :value="index"
                    class="ingredient-item"
                  >
                    <div class="ingredient-inner">
                      <div class="ingredient-content">
                        <div class="ingredient-details">
                          <span v-if="ingredient.amount" class="ingredient-amount">{{ roundNumberIfNeeded(ingredient.amount * portionRatio) }}</span>
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
                  </neb-checkbox>
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
                  <neb-checkbox
                    v-for="(step, index) in recipe.steps"
                    :key="index"
                    align="top"
                    class="step-item"
                  >
                    <p class="step-description">
                      {{ step }}
                    </p>
                  </neb-checkbox>
                </div>

                <p v-else class="empty-message">
                  No instructions provided for this recipe.
                </p>
              </section>
            </main>
          </neb-state-content>
        </template>
      </neb-state-content>
    </div>
  </page-layout>
</template>

<style scoped>
.recipe-detail {
  min-height: 100vh;
  max-width: 1200px;
  margin: 0 auto;
  padding: var(--space-6);
  border-radius: var(--radius-large);
  background: var(--neutral-color-25);
  box-shadow: var(--shadow-md);
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
}

.recipe-meta {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-6);
  width: fit-content;
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
  width: fit-content;
}

.meal-types {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  width: fit-content;
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
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.ingredients-dropdown {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  padding: var(--space-4);
  background: white;
  border: 1px solid var(--neutral-color-200);
  border-radius: var(--radius-default);
  box-shadow: var(--shadow-lg);
  min-width: 250px;

  :deep(.neb-content-wrapper) {
    align-items: center;
  }
}

.portion-controls {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  font-weight: 600;
  border: 1px solid var(--neutral-color-200);
  border-radius: var(--radius-default);
  overflow: hidden;
}

.add-to-list-wrapper {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.list-buttons {
  :deep(.neb-button) {
    justify-content: flex-start;
  }
}

.ingredients-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.ingredient-item {
  gap: var(--space-3);
  padding: var(--space-3);
  border: 1px solid var(--neutral-color-100);
  border-radius: var(--radius-default);
  transition: all var(--duration-default);
}

.ingredient-inner {
  display: flex;
  align-items: center;
  gap: var(--space-3);

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
  font-size: var(--text-md);
  font-weight: normal;
  cursor: text;
  user-select: text;
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
  gap: var(--space-2);
}

.step-item {
  display: flex;
  gap: var(--space-4);
  padding: var(--space-4);
  border: 1px solid var(--neutral-color-100);
  border-radius: var(--radius-default);
}

.step-description {
  font-size: var(--text-md);
  font-weight: normal;
  color: var(--neutral-color-700);
  user-select: text;
  cursor: text;
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

  .recipe-detail {
    padding: 0;
    box-shadow: none;
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

  .ingredients-dropdown {
    background: var(--neutral-color-950);
    border: 1px solid var(--neutral-color-800);
  }

  .portion-controls {
    border: 1px solid var(--neutral-color-800);
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

  .recipe-image {
    border: 1px solid var(--neutral-color-700);
  }
}
</style>
