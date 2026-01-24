import type { InMealRuleConditions, OutCuisine, OutIngredient, OutMeal, OutRecipeTag } from '~/db'

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

export function useConditionCount(conditions: Ref<InMealRuleConditions>) {
  return computed(() => {
    return conditions.value.include.meals.items.length
      + conditions.value.include.tags.items.length
      + conditions.value.include.cuisines.items.length
      + conditions.value.include.ingredients.items.length
      + conditions.value.exclude.meals.length
      + conditions.value.exclude.tags.length
      + conditions.value.exclude.cuisines.length
      + conditions.value.exclude.ingredients.length
  })
}
