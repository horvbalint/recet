import type { BoundQuery, RecordId } from 'surrealdb'
import type { OutCuisine, OutIngredient, OutMeal, OutRecipeTag } from '~/db'
import type { Recipe } from '~/pages/index.vue'

// VIEW TRANSITION
const cachedRecipe = ref<Recipe | null>(null)
export function setCachedRecipe(recipe: Recipe) {
  cachedRecipe.value = recipe
}
export function getCachedRecipe(recipeId: RecordId<'recipe'>['id']) {
  if (recipeId !== cachedRecipe.value?.id.id)
    return null

  return cachedRecipe.value
}

export function getRecipeViewTransitionNames(recipeId: RecordId<'recipe'>['id']) {
  return computed(() => {
    if (recipeId !== cachedRecipe.value?.id.id)
      return {}

    return {
      image: 'recipe-image',
    }
  })
}

// RECIPE IMAGE HANDLING
export async function getRecipeImage(recipeId: RecordId<'recipe'>) {
  const [buffer] = await db
    .query(surql`file::get(type::file('recipe_images', ${recipeId.id}))`)
    .collect<[ArrayBuffer | null]>()

  if (buffer)
    return new File([buffer!], 'recipe-image.jpg', { type: 'image/*' })
  else
    return null
}

const cachedRecipeImages = new Map<RecordId<'recipe'>['id'], string | null>()
export async function getRecipeImageUrl(recipeId: RecordId<'recipe'>) {
  if (cachedRecipeImages.has(recipeId.id))
    return cachedRecipeImages.get(recipeId.id)!

  const image = await getRecipeImage(recipeId)

  const url = image && URL.createObjectURL(image)
  cachedRecipeImages.set(recipeId.id, url)
  return url
}

export async function setImageOnRecipe(recipeId: RecordId<'recipe'>, image: File) {
  const buffer = await image.arrayBuffer()
  await db.query(surql`fn::add_image_to_recipe(${recipeId}, ${buffer})`)
  cachedRecipeImages.delete(recipeId.id)
}

// RECIPE STATE + QUERY
const recipesPerPage = isMobile.value ? 5 : 9
const pageIndex = ref(0)
let firstPageQueriedAt = new Date()
const recipes = ref<Recipe[]>([])
const recipeCount = ref<number | null>(null)
const filterData = ref<{
  cuisenes: OutCuisine[]
  tags: OutRecipeTag[]
  meals: OutMeal[]
  ingredients: OutIngredient[]
}>()

const searchTerm = ref('')
const selectedCuisines = ref<OutCuisine['id'][]>([])
const selectedTags = ref<OutRecipeTag['id'][]>([])
const selectedMeals = ref<OutMeal['id'][]>([])
const selectedIngredients = ref<OutIngredient['id'][]>([])

function constructWhereClause(query: BoundQuery) {
  query.append(surql` WHERE household = ${currentHousehold.value!.id} && created_at <= ${firstPageQueriedAt}`)

  if (searchTerm.value)
    query.append(surql` && name @@ ${searchTerm.value}`)

  if (selectedCuisines.value.length)
    query.append(surql` && cuisine IN ${selectedCuisines.value}`)
  if (selectedTags.value.length)
    query.append(surql` && tags.intersect(${selectedTags.value}).len() > 0`)
  if (selectedMeals.value.length)
    query.append(surql` && meal.intersect(${selectedMeals.value}).len() > 0`)
  if (selectedIngredients.value.length)
    query.append(surql` && ingredients.ingredient.intersect(${selectedIngredients.value}).len() > 0`)

  return query
}

function constructCountQuery() {
  const query = surql`SELECT VALUE count() FROM ONLY recipe`
  constructWhereClause(query)
  query.append(surql` GROUP ALL`)

  return query
}

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
    query.append(surql`,search::score(0) as score FROM recipe`)
  else
    query.append(surql`FROM recipe`)

  if (searchTerm.value) {
    if (currentHousehold.value!.language === 'hu')
      query.append(surql` WITH INDEX hungarian_search_name`)
    else
      query.append(surql` WITH INDEX english_search_name`)
  }

  constructWhereClause(query)

  if (searchTerm.value)
    query.append(surql` ORDER BY score, created_at DESC`)
  else
    query.append(surql` ORDER BY created_at DESC`)

  query.append(surql` LIMIT ${recipesPerPage} START ${pageIndex.value * recipesPerPage}`)

  return query
}

const conditionWatchSources = [currentHousehold, searchTerm, selectedCuisines, selectedIngredients, selectedMeals, selectedTags]

export function clearRecipeCache() {
  pageIndex.value = 0
  recipes.value = []
  recipeCount.value = null
  firstPageQueriedAt = new Date()
}

export function useRecipeState() {
  const { data, status, error, refresh } = useAsyncData('recipes', async () => {
    const recipeQuery = constructRecipeQuery()
    const countQuery = constructCountQuery()

    const [[recipes], [count]] = await Promise.all([
      db.query(recipeQuery).collect<[Recipe[]]>(),
      db.query(countQuery).collect<[number]>(),
    ])

    return { recipeChunks: recipes, recipeCount: count }
  }, { immediate: false, watch: [...conditionWatchSources, pageIndex] })

  if (recipeCount.value === null)
    refresh()

  watch(data, () => {
    recipes.value.push(...data.value?.recipeChunks || [])
    recipeCount.value = data.value?.recipeCount || 0
  })

  watch(conditionWatchSources, () => {
    clearRecipeCache()
  }, {
    flush: 'sync',
  })

  const { data: filterDataTemp, status: filterDataStatus, refresh: queryFilterData } = useAsyncData('filter-data', async () => {
    const [cuisenes, tags, meals, ingredients] = await db
      .query(surql`
        SELECT id, name, color, flag FROM cuisine ORDER BY name ASC;
        SELECT id, name, color, icon FROM recipe_tag ORDER BY name ASC;
        SELECT id, name, color FROM meal ORDER BY name ASC;
        SELECT id, name FROM ingredient ORDER BY name ASC;
      `)
      .collect<[OutCuisine[], OutRecipeTag[], OutMeal[], OutIngredient[]]>()

    return { cuisenes, tags, meals, ingredients }
  }, {
    immediate: false,
  })
  watch(filterDataTemp, () => filterData.value = filterDataTemp.value)

  return {
    filter: {
      data: {
        data: filterData,
        status: filterDataStatus,
        refresh: queryFilterData,
      },
      conditions: {
        searchTerm,
        selectedCuisines,
        selectedTags,
        selectedMeals,
        selectedIngredients,
      },
    },
    recipes: {
      data: {
        pageIndex,
        recipes,
        recipeCount,
      },
      status,
      error,
      refresh,
    },
  }
}
