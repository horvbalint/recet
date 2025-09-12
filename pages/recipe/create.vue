<script setup lang="ts">
import { RecordId } from 'surrealdb'
import type { InRecipe, OutIngredient, OutUnit, OutCuisine, OutMeal, OutRecipeTag } from '~/db'

const router = useRouter()

const formData = ref<Partial<InRecipe>>({
  name: '',
  ingredients: [],
  steps: [],
  tags: [],
  meal: [],
  cuisine: undefined
})

const isFormValid = ref(false)

// Modal states
type Table = 'ingredient' | 'unit' | 'cuisine' | 'meal' | 'recipe_tag'
const dynamicCreateTable = ref<Table | null>(null)
const dynamicCreateSearchTerm = ref<string>('')

const { data, refresh } = await useAsyncData(async () => {
  const [ingredients, units, cuisines, meals, recipeTags] = await db.query<[
    OutIngredient[],
    OutUnit[],
    OutCuisine[],
    OutMeal[],
    OutRecipeTag[]
  ]>(surql`
    SELECT id, name FROM ingredient ORDER BY name ASC;
    SELECT id, name FROM unit ORDER BY name ASC;
    SELECT id, name, color, flag FROM cuisine ORDER BY name ASC;
    SELECT id, name, color FROM meal ORDER BY name ASC;
    SELECT id, name, color, icon FROM recipe_tag ORDER BY name ASC;
  `)
  
  return {
    ingredients,
    units,
    cuisines,
    meals,
    recipeTags
  }
})

async function handleSubmit() {
  try {
    const author = new RecordId('user', '1o4s0mdx4t5t8bbt3qk2')
    
    const [result] = await db.query<[OutIngredient[]]>('INSERT INTO recipe $data RETURN id', { data: {
      ...formData.value,
      author,
      ingredients: formData.value.ingredients?.map(ing => ({...ing, unit: ing.unit?.id, ingredient: ing.ingredient.id})),
      steps: formData.value.steps?.map(step => step.trim()).filter(step => step),
      tags: formData.value.tags?.map(tag => tag.id),
      meal: formData.value.meal?.map(meal => meal.id),
      cuisine: formData.value.cuisine?.id
    } })
    
    if (result?.[0]?.id) {
      useNebToast({ 
        type: 'success', 
        title: 'Recipe created!', 
        description: 'Your recipe has been saved successfully.' 
      })
      
      router.push(`/recipe/${result[0].id.id}`)
    }
  } catch (error) {
    console.error(error)
    useNebToast({ 
      type: 'error', 
      title: 'Creation failed!', 
      description: 'Could not save the recipe. Please try again.' 
    })
  }
}

function handleCancel() {
  router.push('/')
}

// Handlers for creating new master data
function handleCreateCuisine(searchTerm: string) {
  dynamicCreateSearchTerm.value = searchTerm
  dynamicCreateTable.value = 'cuisine'
}

function handleCreateMeal(searchTerm: string) {
  dynamicCreateSearchTerm.value = searchTerm
  dynamicCreateTable.value = 'meal'
}

function handleCreateTag(searchTerm: string) {
  dynamicCreateSearchTerm.value = searchTerm
  dynamicCreateTable.value = 'recipe_tag'
}

const ingridientIndex = ref<number | null>(null)
function handleCreateIngredient(searchTerm: string, index: number) {
  ingridientIndex.value = index
  dynamicCreateSearchTerm.value = searchTerm
  dynamicCreateTable.value = 'ingredient'
}

function handleCreateUnit(searchTerm: string, index: number) {
  ingridientIndex.value = index
  dynamicCreateSearchTerm.value = searchTerm
  dynamicCreateTable.value = 'unit'
}

// Handlers for when new items are created
function onCuisineCreated(cuisine: OutCuisine) {
  formData.value.cuisine = cuisine
  refresh()
}

function onMealCreated(meal: OutMeal) {
  if (!formData.value.meal)
    formData.value.meal = []
  formData.value.meal.push(meal)

  refresh()
}

function onTagCreated(tag: OutRecipeTag) {
  if (!formData.value.tags)
    formData.value.tags = []
  formData.value.tags.push(tag)
  
  refresh()
}

function onIngredientCreated(ingredient: OutIngredient) {
  formData.value.ingredients![ingridientIndex.value!]!.ingredient = ingredient
  refresh()
}

function onUnitCreated(unit: OutUnit) {
  formData.value.ingredients![ingridientIndex.value!]!.unit = unit
  refresh()
}
</script>

<template>
  <div class="recipe-create">
    <neb-content-header
      title="Create Recipe"
      description="Add a new recipe to your collection"
      type="page"
      has-separator
    >
      <template #actions>
        <neb-button type="secondary" @click="handleCancel">
          Cancel
        </neb-button>

        <neb-button 
          type="primary" 
          :disabled="!isFormValid"
          @click="handleSubmit"
        >
          <icon name="material-symbols:save-rounded" />
          Save Recipe
        </neb-button>
      </template>
    </neb-content-header>

    <main class="main-content">
      <div class="form-container">
        <neb-validator v-model="isFormValid">
          <div class="form-sections">
            <div class="form-section">
              <neb-content-header
                title="Basic Information"
                type="section"
              />
              
              <div class="basic-info-fields">
                <neb-input
                  v-model="formData.name"
                  label="Recipe Name"
                  placeholder="Enter recipe name"
                  required
                />

                <div class="selects-row">
                  <neb-select
                    v-model="formData.cuisine"
                    :options="data!.cuisines"
                    label="Cuisine"
                    placeholder="Select cuisine"
                    track-by-key="name"
                    label-key="name"
                    @new="handleCreateCuisine"
                  />

                  <neb-select
                    v-model="formData.meal"
                    :options="data!.meals"
                    label="Meals"
                    placeholder="Select meals"
                    track-by-key="name"
                    label-key="name"
                    multiple
                    @new="handleCreateMeal"
                  />

                  <neb-select
                    v-model="formData.tags"
                    :options="data!.recipeTags"
                    label="Tags"
                    placeholder="Select tags"
                    track-by-key="name"
                    label-key="name"
                    multiple
                    @new="handleCreateTag"
                  />
                </div>
              </div>
            </div>

            <neb-form-list 
              v-model="formData.ingredients"
              label="Ingredients"
              class="form-section"
              with-initial-item
            >
              <template #default="{ item: ingredient, index }">
                <div class="ingredient-fields">
                  <neb-select
                    v-model="ingredient.ingredient"
                    label="Ingredient"
                    :options="data!.ingredients!"
                    label-key="name"
                    track-by-key="name"
                    placeholder="Select ingredient"
                    required
                    @new="handleCreateIngredient($event, index)"
                  />
                  
                  <neb-input 
                    v-model="ingredient.amount" 
                    label="Amount" 
                    type="number"
                    placeholder="0"
                  />
                  
                  <neb-select
                    v-model="ingredient.unit"
                    label="Unit"
                    :options="data!.units!"
                    label-key="name"
                    track-by-key="name"
                    placeholder="Select unit"
                    allow-empty
                    @new="handleCreateUnit($event, index)"
                  />
                  
                  <neb-input 
                    v-model="ingredient.description" 
                    label="Description" 
                    placeholder="e.g., diced, chopped"
                  />
                </div>
              </template>
            </neb-form-list>

            <neb-form-list 
              v-model="formData.steps"
              label="Instructions"
              class="form-section"
              :factory="() => ''"
              with-initial-item
            >
              <template #default="{ index }">
                <neb-textarea 
                  :required="true"
                  v-model="formData.steps![index]"
                  :label="`Step ${index + 1}`"
                  placeholder="Describe this step..."
                />
              </template>
            </neb-form-list>
          </div>
        </neb-validator>
      </div>
    </main>
  </div>

  <!-- Create modals -->
  <cuisine-master-data-modal 
    v-if="dynamicCreateTable === 'cuisine'"
    :model-value="true"
    @update:model-value="dynamicCreateTable = null"
    :initial-data="{ name: dynamicCreateSearchTerm }"
    @saved="onCuisineCreated"
  />
  
  <meal-master-data-modal
    v-if="dynamicCreateTable === 'meal'"
    :model-value="true"
    @update:model-value="dynamicCreateTable = null"
    :initial-data="{ name: dynamicCreateSearchTerm }"
    @saved="onMealCreated"
  />
  
  <tag-master-data-modal
    v-if="dynamicCreateTable === 'recipe_tag'"
    :model-value="true"
    @update:model-value="dynamicCreateTable = null"
    :initial-data="{ name: dynamicCreateSearchTerm }"
    @saved="onTagCreated"
  />
  
  <ingredient-master-data-modal 
    v-if="dynamicCreateTable === 'ingredient'"
    :model-value="true"
    @update:model-value="dynamicCreateTable = null"
    :initial-data="{ name: dynamicCreateSearchTerm }"
    @saved="onIngredientCreated"
  />
  
  <unit-master-data-modal 
    v-if="dynamicCreateTable === 'unit'"
    :model-value="true"
    @update:model-value="dynamicCreateTable = null"
    :initial-data="{ name: dynamicCreateSearchTerm }"
    @saved="onUnitCreated"
  />
</template>

<style scoped>
.recipe-create {
  min-height: 100vh;
  background: var(--neutral-color-25);
  padding: var(--space-6);
}

.main-content {
  max-width: 800px;
  margin: 0 auto;
  padding-top: var(--space-6);
}

.form-container {
  border-radius: var(--radius-large);
  border: 1px solid var(--neutral-color-100);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
}

.form-sections {
  display: flex;
  flex-direction: column;
}

.form-section {
  padding: var(--space-6);
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.form-section:not(:last-child) {
  border-bottom: 1px solid var(--neutral-color-100);
}

.basic-info-fields {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.selects-row {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: var(--space-4);
}

.ingredient-fields {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1.5fr;
  gap: var(--space-3);
}

@media (--tablet-viewport) {
  .recipe-create {
    padding: var(--space-4);
  }

  .main-content {
    padding-top: var(--space-4);
  }

  .form-section {
    padding: var(--space-4);
  }

  .basic-info-fields {
    gap: var(--space-3);
  }

  .selects-row {
    grid-template-columns: 1fr;
    gap: var(--space-3);
  }

  .ingredient-fields {
    grid-template-columns: 1fr;
    gap: var(--space-3);
  }
}

@media (--mobile-lg-viewport) {
  .recipe-create {
    padding: var(--space-3) !important;
  }

  .main-content {
    padding-top: var(--space-3) !important;
  }

  .form-section {
    padding: var(--space-3) !important;
  }
}

.dark-mode {
  .recipe-create {
    background: var(--neutral-color-950);
  }

  .form-container {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);
  }

  .form-section {
    border-color: var(--neutral-color-800);
  }
}
</style>
