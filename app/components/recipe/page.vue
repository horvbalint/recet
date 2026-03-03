<script setup lang="ts">
import type { Menu } from 'nebula/components/overlays/neb-menu.vue'
import type { RecordId } from 'surrealdb'

const { t } = useI18n()
const props = defineProps<{
  recipeId: string
  guest?: true
}>()

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
  recipes: Array<{
    recipe: {
      id: RecordId<'recipe'>
      name: string
    }
    description?: string
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
  public: boolean
}

const { data: queriedRecipe, status: queryStatus, error, refresh } = useAsyncData<Recipe | null>(`recipe-${props.recipeId}`, async () => {
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
        public,
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
        }),
        recipes.map(|$r| {
          recipe: $r.recipe.{id, name},
          description: $r.description
        })
      FROM ONLY
        type::record('recipe', ${props.recipeId})
    `)
    .collect<[Recipe]>()

  return result
}, {
  deep: true,
})

const recipe = computed<Recipe | null | undefined>(() => {
  const cachedRecipe = getCachedRecipe(props.recipeId)
  if (!cachedRecipe || queriedRecipe.value)
    return queriedRecipe.value

  return {
    ...cachedRecipe,
    ingredients: [],
    recipes: [],
    steps: [],
    portions: 1,
    public: false,
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
const checkedRecipes = ref<number[]>([])
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

    const checkedIngredientIndexes = checkedIngredients.value.length ? checkedIngredients.value : undefined
    const ingredientIndexesToAdd = checkedIngredientIndexes?.filter(index => !recipe.value!.ingredients[index]!.skip_from_shopping_list)
    const checkedRecipeIndexes = checkedRecipes.value.length ? checkedRecipes.value : undefined

    await db.query(surql`
      fn::add_recipe_to_shopping_list(
        ${recipe.value!.id},
        ${shoppingListId},
        ${ingredientIndexesToAdd},
        ${checkedRecipeIndexes},
        ${portionRatio.value},
        []
      )
    `)

    checkedIngredients.value = []
    checkedRecipes.value = []

    useNebToast({ type: 'success', title: t('recipes.detail.ingredientsAdded.title'), description: t('recipes.detail.ingredientsAdded.description') })
  }
  catch (err) {
    console.error('Error adding ingredients to shopping list:', err)
    useNebToast({ type: 'error', title: t('recipes.detail.ingredientsAddError.title'), description: t('recipes.detail.ingredientsAddError.description') })
  }
  finally {
    isAddingToList.value = false
  }
}

const inProgress = ref(false)

async function togglePublic() {
  try {
    inProgress.value = true

    await db
      .query(surql`UPDATE type::record('recipe', ${props.recipeId}) SET public = ${!recipe.value!.public}`)
      .collect()

    recipe.value!.public = !recipe.value!.public
    clearRecipeCache()

    useNebToast({
      type: 'success',
      title: recipe.value!.public ? t('recipes.detail.nowPublic.title') : t('recipes.detail.nowPrivate.title'),
      description: recipe.value!.public ? t('recipes.detail.nowPublic.description') : t('recipes.detail.nowPrivate.description'),
      actions: recipe.value!.public
        ? [{
            text: t('recipes.detail.copyLink'),
            callback: () => copyPublicUrl(props.recipeId),
          }]
        : [],
    })
  }
  catch (err) {
    console.error('Error updating recipe visibility:', err)
    useNebToast({ type: 'error', title: t('recipes.detail.visibilityError.title'), description: t('recipes.detail.visibilityError.description') })
  }
  finally {
    inProgress.value = false
  }
}

async function deleteRecipe() {
  try {
    const confirmed = await useNebConfirm({ title: t('recipes.detail.deleteConfirm.title'), description: t('recipes.detail.deleteConfirm.description') })
    if (!confirmed)
      return

    inProgress.value = true

    await db
      .query(surql`DELETE type::record('recipe', ${props.recipeId})`)
      .collect()
    clearRecipeCache()

    useNebToast({ type: 'success', title: t('recipes.detail.deleteSuccess.title'), description: t('recipes.detail.deleteSuccess.description') })
    await navigateTo('/')
  }
  catch (err) {
    console.error('Error deleting recipe:', err)
useNebToast({ type: 'error', title: t('recipes.detail.deleteError.title'), description: t('recipes.detail.deleteError.description') })
  }
  finally {
    inProgress.value = false
  }
}

async function editRecipe() {
  await navigateTo(`/recipe/create/${props.recipeId}`)
}

async function copyRecipe() {
  await navigateTo(`/recipe/create/${props.recipeId}?copy=true`)
}

const menus = computed<Menu[]>(() => {
  return [
    ...recipe.value?.public
      ? [
          { text: t('recipes.detail.copyPublicLink'), icon: 'material-symbols:copy-all-outline-rounded', callback: () => copyPublicUrl(props.recipeId) },
          { text: t('recipes.detail.makePrivate'), icon: 'material-symbols:public-off-rounded', callback: togglePublic },
        ]
      : [{ text: t('recipes.detail.makePublic'), icon: 'material-symbols:public', callback: togglePublic }],
    { text: t('recipes.detail.copyRecipe'), icon: 'material-symbols:content-copy-outline-rounded', callback: copyRecipe, segment: recipe.value?.public },
    { text: t('recipes.detail.deleteRecipe'), icon: 'material-symbols:delete-outline-rounded', callback: deleteRecipe, segment: true, desctructive: true },
  ]
})

watch(currentHousehold, async () => await navigateTo('/'))
</script>

<template>
  <div class="recipe-detail">
    <neb-state-content :status :refresh :error-title="$t('recipes.detail.loadError.title')" :error-description="error?.message">
      <neb-empty-state
        v-if="!recipe"
        icon="material-symbols:menu-book-2-outline-rounded"
        :title="$t('recipes.detail.empty.notFound.title')"
        :description="$t('recipes.detail.empty.notFound.description')"
      >
        <neb-button v-if="!props.guest" @click="navigateTo('/')">
          <icon name="material-symbols:arrow-back-rounded" />
          {{ $t('recipes.detail.backToRecipes') }}
        </neb-button>
      </neb-empty-state>

      <template v-else>
        <header>
          <div class="recipe-hero">
            <recipe-image class="recipe-image" :recipe :width-px="600" :height-px="400">
              <div v-if="!props.guest" class="recipe-actions">
                <neb-button type="secondary-neutral" small :disabled="inProgress" :loading="inProgress" @click="editRecipe()">
                  <icon name="material-symbols:edit-outline-rounded" />
                </neb-button>

                <neb-menu :menus>
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
                  <span>{{ $t('recipes.detail.ingredients', { count: recipe.ingredients?.length || 0 }) }}</span>
                </div>

                <div v-if="recipe.recipes?.length" class="meta-item">
                  <icon name="material-symbols:menu-book-outline-rounded" />
                  <span>{{ $t('recipes.detail.recipes', { count: recipe.recipes.length }) }}</span>
                </div>

                <div class="meta-item">
                  <icon name="material-symbols:format-list-numbered-rounded" />
                  <span>{{ $t('recipes.detail.steps', { count: recipe.steps?.length || 0 }) }}</span>
                </div>

                <div v-if="recipe.cooking_time_minutes" class="meta-item">
                  <icon name="material-symbols:schedule-outline-rounded" />
                  <span>{{ recipe.cooking_time_minutes }} {{ $t('common.minutes') }}</span>
                </div>
              </div>

              <div class="recipe-author">
                <neb-avatar-card
                  :avatar="{ text: recipe.author?.username?.[0]?.toUpperCase() || '?', size: '40px' }"
                  :title="$t('recipes.detail.byAuthor', { author: recipe.author?.username || 'Unknown' })"
                  :text="$t('recipes.detail.createdOn', { date: new Date(recipe.created_at).toLocaleDateString() })"
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
                :title="$t('recipes.detail.ingredientsSection')"
                type="page"
                has-separator
              >
                <template v-if="!props.guest" #actions>
                  <neb-dropdown :floating-options="{ placement: 'bottom-end' }">
                    <template #trigger="{ toggle }">
                      <neb-button type="tertiary-neutral" small :disabled="isAddingToList" :loading="isAddingToList" @click="toggle()">
                        <icon name="material-symbols:more-vert" />
                      </neb-button>
                    </template>

                    <template #content="{ close }">
                      <div class="ingredients-dropdown">
                        <neb-content-header v-if="portions" :title="$t('recipes.detail.portions')" type="paragraph" has-separator>
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
                            :title="checkedIngredients.length ? $t('recipes.detail.addToListSelected', { count: checkedIngredients.length + checkedRecipes.length }) : $t('recipes.detail.addToList')"
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

              <div v-if="recipe.recipes?.length || recipe.ingredients?.length" class="ingredients-list">
                <neb-checkbox
                  v-for="(subRecipe, index) in recipe.recipes"
                  :key="subRecipe.recipe.id.id.toString()"
                  v-model="checkedRecipes"
                  :value="index"
                  class="ingredient-item"
                >
                  <div class="ingredient-inner">
                    <div class="ingredient-content">
                      <neb-dropdown>
                        <template #trigger="{ toggle }">
                          <neb-badge
                            class="sub-recipe-badge"
                            @click.stop.prevent="toggle()"
                          >
                            {{ subRecipe.recipe.name }}
                          </neb-badge>
                        </template>

                        <template #content="{ isOpen }">
                          <recipe-card v-if="isOpen" :recipe-id="subRecipe.recipe.id" class="sub-recipe-card" />
                        </template>
                      </neb-dropdown>

                      <span v-if="subRecipe.description" class="sub-recipe-description">{{ subRecipe.description }}</span>
                    </div>

                    <neb-tooltip :title="$t('recipes.detail.tooltip.isRecipe')">
                      <icon name="material-symbols:menu-book-outline-rounded" />
                    </neb-tooltip>
                  </div>
                </neb-checkbox>

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
                      v-if="ingredient.skip_from_shopping_list && !props.guest"
                      :title="$t('recipes.detail.tooltip.skipFromList')"
                    >
                      <icon name="material-symbols:receipt-long-off-outline-rounded" />
                    </neb-tooltip>
                  </div>
                </neb-checkbox>
              </div>

              <p v-else class="empty-message">
                {{ $t('recipes.detail.empty.noIngredients') }}
              </p>
            </section>

            <section class="instructions-section">
              <neb-content-header
                :title="$t('recipes.detail.instructionsSection')"
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
                {{ $t('recipes.detail.empty.noInstructions') }}
              </p>
            </section>
          </main>
        </neb-state-content>
      </template>
    </neb-state-content>
  </div>
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
  :deep(img),
  :deep(canvas),
  :deep(.image-placeholder) {
    border-radius: var(--radius-large);
    border: 1px solid var(--neutral-color-200);
  }

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

  &.public {
    cursor: pointer;
  }
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
  word-break: break-word;
  cursor: text;
}

.empty-message {
  color: var(--neutral-color-500);
  font-style: italic;
  text-align: center;
  padding: var(--space-8);
}

.sub-recipe-trigger {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  cursor: pointer;
}

.sub-recipe-name {
  font-size: var(--text-md);
  font-weight: 500;
  color: var(--neutral-color-700);
}

.sub-recipe-expand-icon {
  font-size: 16px !important;
  color: var(--neutral-color-400);
  transition: color var(--duration-default);

  .sub-recipe-trigger:hover & {
    color: var(--neutral-color-600);
  }
}

.sub-recipe-badge {
  cursor: pointer;
}

.sub-recipe-description {
  color: var(--neutral-color-500);
  font-size: var(--text-sm);
  font-style: italic;
}

.sub-recipe-card {
  width: 300px;
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

  .sub-recipe-name {
    color: var(--neutral-color-300);
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
    :deep(img),
    :deep(canvas),
    :deep(.image-placeholder) {
      border: 1px solid var(--neutral-color-700);
    }
  }

  .recipe-visibility {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);

    .visibility-label {
      color: var(--neutral-color-200);

      .icon {
        color: var(--neutral-color-400);
      }
    }

    .visibility-description {
      color: var(--neutral-color-400);
    }
  }
}
</style>
