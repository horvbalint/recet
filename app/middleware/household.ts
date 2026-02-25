export default defineNuxtRouteMiddleware(async () => {
  const { data, error, refresh } = householdQuery
  await refresh()

  if (error.value)
    throw createError({ message: error.value.message, cause: error.value })

  const stored = localStorage.getItem('currentHousehold')
  const sameId = data.value!.find(h => h.id.toString() === stored)

  const householdToUse = sameId ?? data.value![0]
  if (!householdToUse)
    return navigateTo('/create-first-household')

  switchHousehold(householdToUse)
})
