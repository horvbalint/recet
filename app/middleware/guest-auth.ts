import type { RecordId } from 'surrealdb'

export default defineNuxtRouteMiddleware(async (to) => {
  const recipeId = to.params.id as string

  if (await canReadRecipeAsUser(recipeId))
    return

  await signInAsRecipeGuest(recipeId)
})

// signing in as a guest replaces whatever session is active with a 5 minute one, so members
// of the recipe's household - who can read it anyway - are left with their own session
async function canReadRecipeAsUser(recipeId: string) {
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
