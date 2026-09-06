import type { RecordId } from 'surrealdb'

export default defineNuxtRouteMiddleware(async (to) => {
  const recipeId = to.params.id as string

  if (await canReadRecipeAsUser(recipeId))
    return

  await db.signin({
    access: 'recipe_guest',
    variables: {
      recipe_id: recipeId,
    },
  })
})

async function canReadRecipeAsUser(recipeId: string) {
  if (!hasStoredUserTokens())
    return false

  try {
    await authenticateWithToken()

    if (!await db.auth())
      return false

    const [recipe] = await db
      .query(surql`SELECT VALUE id FROM ONLY type::record('recipe', ${recipeId})`)
      .collect<[RecordId<'recipe'> | null]>()

    return !!recipe
  }
  catch {
    return false
  }
}
