export default defineNuxtRouteMiddleware(async (to) => {
  await db.signin({
    access: 'recipe_guest',
    variables: {
      recipe_id: to.params.id,
    },
  })
})
