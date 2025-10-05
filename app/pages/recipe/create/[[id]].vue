<script setup lang="ts">
import type { InRecipe, OutCuisine, OutIngredient, OutMeal, OutRecipeTag, OutUnit } from '~/db'

definePageMeta({
  layout: 'app',
})

const formData = ref<Partial<InRecipe>>({
  name: '',
  ingredients: [],
  steps: [],
  tags: [],
  meal: [],
  cuisine: undefined,
})
const selectedImage = ref<File | null>(null)

const recipeId = useRoute().params.id
const isEdit = !!recipeId
const headerTitle = isEdit ? 'Edit Recipe' : 'Create Recipe'
const headerDescription = isEdit ? 'Edit the details of the recipe' : 'Add a new recipe to your collection'

const { data: recipeToEdit, status: recipeStatus, refresh: recipeRefresh, error: recipeError } = useAsyncData(async () => {
  if (!recipeId)
    return null

  const [recipe] = await db.query<[InRecipe]>(surql`
    SELECT * FROM ONLY type::thing('recipe', ${recipeId})
  `)

  return recipe
})

let originalImage: null | File = null
watchOnce(recipeToEdit, () => {
  if (!recipeToEdit.value)
    return

  formData.value = recipeToEdit.value
  selectedImage.value = recipeToEdit.value.image ? new File([recipeToEdit.value.image], 'recipe-image.jpg', { type: 'image/jpeg' }) : null
  originalImage = selectedImage.value
})

const { data: masterData, status: masterDataStatus, refresh: masterDataRefresh, error: masterDataError } = useAsyncData(async () => {
  const [ingredients, units, cuisines, meals, recipeTags] = await db.query<[
    OutIngredient[],
    OutUnit[],
    OutCuisine[],
    OutMeal[],
    OutRecipeTag[],
  ]>(surql`
    SELECT id, name FROM ingredient WHERE household = ${currentHousehold.value!.id} ORDER BY name ASC;
    SELECT id, name FROM unit WHERE household = ${currentHousehold.value!.id} ORDER BY name ASC;
    SELECT id, name, color, flag FROM cuisine WHERE household = ${currentHousehold.value!.id} ORDER BY name ASC;
    SELECT id, name, color FROM meal WHERE household = ${currentHousehold.value!.id} ORDER BY name ASC;
    SELECT id, name, color, icon FROM recipe_tag WHERE household = ${currentHousehold.value!.id} ORDER BY name ASC;
  `)

  return {
    ingredients,
    units,
    cuisines,
    meals,
    recipeTags,
  }
}, {
  watch: [currentHousehold],
})

const status = nebCombineStatuses(recipeStatus, masterDataStatus)
async function refresh() {
  await Promise.all([
    recipeRefresh(),
    masterDataRefresh(),
  ])
}

const submitting = ref(false)
async function handleSubmit() {
  if (isEdit)
    await updateRecipe()
  else
    await createRecipe()
}

async function createRecipe() {
  try {
    submitting.value = true
    const { blurhash, imageBuffer } = await processRecipeImage(selectedImage.value)

    const [result] = await db.query<[OutIngredient[]]>('INSERT INTO recipe $data RETURN id', { data: {
      ...formData.value,
      author: authUser.value!.id,
      household: currentHousehold.value!.id,
      steps: formData.value.steps?.map(step => step.trim()).filter(step => step),
      image_blur_hash: blurhash,
      image: imageBuffer,
    } })

    useNebToast({ type: 'success', title: 'Recipe created!', description: 'Your recipe has been saved successfully.' })
    await navigateTo(`/recipe/${result[0]!.id.id}`)
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Creation failed!', description: 'Could not save the recipe. Please try again.' })
  }
  finally {
    submitting.value = false
  }
}

async function updateRecipe() {
  try {
    submitting.value = true

    const update: Partial<InRecipe> = {
      ...formData.value,
      steps: formData.value.steps?.map(step => step.trim()).filter(step => step),
    }

    if (selectedImage.value !== originalImage) {
      const { blurhash, imageBuffer } = await processRecipeImage(selectedImage.value)
      update.image_blur_hash = blurhash
      update.image = imageBuffer
    }

    await db.query<[OutIngredient[]]>(surql`UPDATE ONLY ${recipeToEdit.value!.id} MERGE ${update}`)

    useNebToast({ type: 'success', title: 'Recipe updated!', description: 'Your recipe has been saved successfully.' })
    await navigateTo(`/recipe/${recipeId}`)
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Update failed!', description: 'Could not save the recipe. Please try again.' })
  }
  finally {
    submitting.value = false
  }
}

type Table = 'ingredient' | 'unit' | 'cuisine' | 'meal' | 'recipe_tag'
const dynamicCreateTable = ref<Table | null>(null)
const dynamicCreateSearchTerm = ref<string>('')

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

function onCuisineCreated(cuisine: OutCuisine) {
  formData.value.cuisine = cuisine.id
  refresh()
}

function onMealCreated(meal: OutMeal) {
  if (!formData.value.meal)
    formData.value.meal = []
  formData.value.meal.push(meal.id)

  refresh()
}

function onTagCreated(tag: OutRecipeTag) {
  if (!formData.value.tags)
    formData.value.tags = []
  formData.value.tags.push(tag.id)

  refresh()
}

function onIngredientCreated(ingredient: OutIngredient) {
  formData.value.ingredients![ingridientIndex.value!]!.ingredient = ingredient.id
  refresh()
}

function onUnitCreated(unit: OutUnit) {
  formData.value.ingredients![ingridientIndex.value!]!.unit = unit.id
  refresh()
}

const isFormValid = ref(false)
</script>

<template>
  <page-layout>
    <template #content-header>
      <neb-content-header
        :title="headerTitle"
        :description="headerDescription"
        :type="pageHeaderType"
        has-separator
      >
        <template #actions>
          <neb-button
            type="primary"
            small
            :disabled="!isFormValid || submitting"
            :loading="submitting"
            @click="handleSubmit()"
          >
            <icon name="material-symbols:save-outline-rounded" />
            Save Recipe
          </neb-button>
        </template>
      </neb-content-header>
    </template>

    <neb-state-content :status :refresh :error-description="recipeError?.message || masterDataError?.message">
      <neb-validator v-model="isFormValid">
        <div class="form-container">
          <div class="form-section">
            <neb-content-header
              title="Basic Information"
              type="section"
            />

            <div class="basic-info-fields">
              <div class="flex-row">
                <neb-input
                  v-model="formData.name"
                  label="Recipe Name"
                  placeholder="Enter recipe name"
                  required
                />

                <div class="flex-row">
                  <neb-input
                    v-model="formData.portions"
                    label="Portion count"
                    placeholder="e.g., 4"
                    type="number"
                  />

                  <neb-input
                    v-model="formData.cooking_time_minutes"
                    label="Cooking time (minutes)"
                    placeholder="e.g., 30"
                    type="number"
                  />
                </div>
              </div>

              <neb-single-file-picker
                v-model="selectedImage"
                label="Recipe Image"
                accept="image/*"
                placeholder="Upload an image for the recipe"
              />

              <div class="selects-row">
                <neb-select
                  v-model="formData.cuisine"
                  :options="masterData!.cuisines"
                  label="Cuisine"
                  placeholder="Select cuisine"
                  track-by-key="id"
                  label-key="name"
                  :transform-fun="transformId"
                  use-only-tracked-key
                  no-search
                  @new="handleCreateCuisine"
                >
                  <template #option="{ option }">
                    <cuisine-badge :cuisine="option" />
                  </template>

                  <template #selection="{ selected }">
                    <cuisine-badge v-for="cuisine in selected" :key="cuisine.trackValue.toString()" small :cuisine="cuisine.option" />
                  </template>
                </neb-select>

                <neb-select
                  v-model="formData.meal"
                  :options="masterData!.meals"
                  label="Meals"
                  placeholder="Select meals"
                  track-by-key="id"
                  label-key="name"
                  :transform-fun="transformId"
                  use-only-tracked-key
                  multiple
                  no-search
                  @new="handleCreateMeal"
                >
                  <template #option="{ option }">
                    <meal-badge :meal="option" />
                  </template>

                  <template #selection="{ selected }">
                    <meal-badge v-for="meal in selected" :key="meal.trackValue.toString()" small :meal="meal.option" />
                  </template>
                </neb-select>

                <neb-select
                  v-model="formData.tags"
                  :options="masterData!.recipeTags"
                  label="Tags"
                  placeholder="Select tags"
                  track-by-key="id"
                  label-key="name"
                  :transform-fun="transformId"
                  use-only-tracked-key
                  multiple
                  no-search
                  @new="handleCreateTag"
                >
                  <template #option="{ option }">
                    <recipe-tag-badge :tag="option" />
                  </template>

                  <template #selection="{ selected }">
                    <recipe-tag-badge v-for="tag in selected" :key="tag.trackValue.toString()" small :tag="tag.option" />
                  </template>
                </neb-select>
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
                  :options="masterData!.ingredients!"
                  label-key="name"
                  track-by-key="id"
                  placeholder="Select ingredient"
                  :transform-fun="transformId"
                  use-only-tracked-key
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
                  :options="masterData!.units!"
                  label-key="name"
                  track-by-key="id"
                  placeholder="Select unit"
                  :transform-fun="transformId"
                  no-search
                  use-only-tracked-key
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
                v-model="formData.steps![index]"
                :required="true"
                :label="`Step ${index + 1}`"
                placeholder="Describe this step..."
              />
            </template>
          </neb-form-list>
        </div>
      </neb-validator>
    </neb-state-content>

    <!-- Create modals -->
    <cuisine-master-data-modal
      v-if="dynamicCreateTable === 'cuisine'"
      :model-value="true"
      :initial-data="{ name: dynamicCreateSearchTerm }"
      @update:model-value="dynamicCreateTable = null"
      @saved="onCuisineCreated"
    />

    <meal-master-data-modal
      v-if="dynamicCreateTable === 'meal'"
      :model-value="true"
      :initial-data="{ name: dynamicCreateSearchTerm }"
      @update:model-value="dynamicCreateTable = null"
      @saved="onMealCreated"
    />

    <recipe-tag-master-data-modal
      v-if="dynamicCreateTable === 'recipe_tag'"
      :model-value="true"
      :initial-data="{ name: dynamicCreateSearchTerm }"
      @update:model-value="dynamicCreateTable = null"
      @saved="onTagCreated"
    />

    <ingredient-master-data-modal
      v-if="dynamicCreateTable === 'ingredient'"
      :model-value="true"
      :initial-data="{ name: dynamicCreateSearchTerm }"
      @update:model-value="dynamicCreateTable = null"
      @saved="onIngredientCreated"
    />

    <unit-master-data-modal
      v-if="dynamicCreateTable === 'unit'"
      :model-value="true"
      :initial-data="{ name: dynamicCreateSearchTerm }"
      @update:model-value="dynamicCreateTable = null"
      @saved="onUnitCreated"
    />
  </page-layout>
</template>

<style scoped>
.form-container {
  border-radius: var(--radius-large);
  border: 1px solid var(--neutral-color-100);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
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

.flex-row {
  width: 100%;
  display: flex;
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

  .flex-row {
    flex-wrap: wrap;
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
  .form-section {
    padding: var(--space-3) !important;
  }
}

.dark-mode {
  .form-container {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);
  }

  .form-section {
    border-color: var(--neutral-color-800);
  }
}
</style>
