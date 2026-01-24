import type { InMealRuleConditions, OutCuisine, OutIngredient, OutMeal, OutMealRuleConditions, OutRecipeTag } from '~/db'

export function useFilterData() {
  return useAsyncData('recipe-filter-data', async () => {
    const [meals, tags, cuisines, ingredients] = await db
      .query(surql`
      SELECT id, name, color FROM meal WITH NOINDEX ORDER BY name ASC;
      SELECT id, name, color, icon FROM recipe_tag WITH NOINDEX ORDER BY name ASC;
      SELECT id, name, color, flag FROM cuisine WITH NOINDEX ORDER BY name ASC;
      SELECT id, name FROM ingredient WITH NOINDEX ORDER BY name ASC;
    `)
      .collect<[OutMeal[], OutRecipeTag[], OutCuisine[], OutIngredient[]]>()

    return { meals, tags, cuisines, ingredients }
  }, {
    getCachedData: (key, nuxt) => nuxt.payload.data[key],
    immediate: false,
  })
}

export function calcConditionCount(conditions: InMealRuleConditions | OutMealRuleConditions) {
  return conditions.include.meals.items.length
    + conditions.include.tags.items.length
    + conditions.include.cuisines.items.length
    + conditions.include.ingredients.items.length
    + conditions.exclude.meals.length
    + conditions.exclude.tags.length
    + conditions.exclude.cuisines.length
    + conditions.exclude.ingredients.length
}

export function useConditionCount(conditions: Ref<InMealRuleConditions>) {
  return computed(() => calcConditionCount(conditions.value))
}
