import type { ExprLike, RecordId } from 'surrealdb'
import type { InMealRuleConditions, OutMealRuleConditions } from '~/db'
import type { Recipe } from '~/pages/index.vue'
import { and, containsAll, containsAny, eq, inside, lte, matches, not, or, raw } from 'surrealdb'

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

const searchTerm = ref('')
const filterConditions = ref<InMealRuleConditions>(createEmptyMealRuleConditions())

export function constructWhereConditions(conditions: InMealRuleConditions): ExprLike {
  const query_conditions = [
    eq('household', currentHousehold.value!.id),
    lte('created_at', firstPageQueriedAt),
  ]

  if (searchTerm.value)
    query_conditions.push(matches('name', searchTerm.value))

  const inc = conditions.include
  const exc = conditions.exclude

  const hasIncMeals = inc.meals.items.length > 0
  const hasIncTags = inc.tags.items.length > 0
  const hasIncCuisines = inc.cuisines.items.length > 0
  const hasIncIngredients = inc.ingredients.items.length > 0
  const hasAnyInclude = hasIncMeals || hasIncTags || hasIncCuisines || hasIncIngredients

  if (hasAnyInclude) {
    const filter_conditions = []

    if (hasIncMeals) {
      if (inc.meals.operator === 'and')
        filter_conditions.push(containsAll('meal', inc.meals.items))
      else
        filter_conditions.push(containsAny('meal', inc.meals.items))
    }

    if (hasIncTags) {
      if (inc.tags.operator === 'and')
        filter_conditions.push(containsAll('tags', inc.tags.items))
      else
        filter_conditions.push(containsAny('tags', inc.tags.items))
    }

    if (hasIncCuisines)
      filter_conditions.push(inside('cuisine', inc.cuisines.items))

    if (hasIncIngredients) {
      if (inc.ingredients.operator === 'and')
        filter_conditions.push(containsAll('ingredients.ingredient', inc.ingredients.items))
      else
        filter_conditions.push(containsAny('ingredients.ingredient', inc.ingredients.items))
    }

    if (conditions.include_operator === 'and')
      query_conditions.push(and(...filter_conditions))
    else
      query_conditions.push(or(...filter_conditions))
  }

  if (exc.meals.length)
    query_conditions.push(not(containsAny('meal', exc.meals)))
  if (exc.tags.length)
    query_conditions.push(not(containsAny('tags', exc.tags)))
  if (exc.cuisines.length)
    query_conditions.push(not(inside('cuisine', exc.cuisines)))
  if (exc.ingredients.length)
    query_conditions.push(not(containsAny('ingredients.ingredient', exc.ingredients)))

  return and(...query_conditions)
}

function constructCountQuery() {
  const whereConditions = constructWhereConditions(filterConditions.value)
  return surql`SELECT VALUE count() FROM ONLY recipe WHERE ${whereConditions} GROUP ALL`
}

export const fieldsNeededForRecipeCard = `
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

function constructRecipeQuery() {
  const query = surql`SELECT ${raw(fieldsNeededForRecipeCard)} `

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

  const whereConditions = constructWhereConditions(filterConditions.value)
  query.append(surql` WHERE ${whereConditions}`)

  if (searchTerm.value)
    query.append(surql` ORDER BY score, created_at DESC`)
  else
    query.append(surql` ORDER BY created_at DESC`)

  query.append(surql` LIMIT ${recipesPerPage} START ${pageIndex.value * recipesPerPage}`)

  return query
}

const conditionWatchSources = [currentHousehold, searchTerm, filterConditions]

export function clearRecipeCache() {
  pageIndex.value = 0
  recipes.value = []
  recipeCount.value = null
  firstPageQueriedAt = new Date()
}

const refreshTrigger = ref(0)

export function useRecipeState() {
  const { data, status, error, refresh } = useAsyncData('recipes', async () => {
    const recipeQuery = constructRecipeQuery()
    const countQuery = constructCountQuery()

    const [[recipes], [count]] = await Promise.all([
      db.query(recipeQuery).collect<[Recipe[]]>(),
      db.query(countQuery).collect<[number]>(),
    ])

    return { recipeChunks: recipes, recipeCount: count }
  }, { immediate: false, watch: [pageIndex, refreshTrigger] })

  if (recipeCount.value === null)
    refresh()

  watch(data, () => {
    recipes.value.push(...data.value?.recipeChunks || [])
    recipeCount.value = data.value?.recipeCount || 0
  })

  watch(conditionWatchSources, () => {
    clearRecipeCache()
    refreshTrigger.value++
  }, {
    flush: 'sync',
    deep: true,
  })

  return {
    filter: {
      searchTerm,
      conditions: filterConditions,
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
