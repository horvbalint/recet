import type { OutHousehold } from '~/db'

export default defineNuxtRouteMiddleware(async () => {
  householdQuery.value = await useAsyncData(async () => {
    const [households] = await db.query<[OutHousehold[]]>(surql`${authUser.value!.id} -> member -> household.{ id, name }`)
    return households
  })

  const stored = localStorage.getItem('currentHousehold')
  const sameId = householdQuery.value!.data.find(h => h.id.toString() === stored)

  const householdToUse = sameId ?? householdQuery.value!.data[0]
  if (!householdToUse)
    return navigateTo('/create-first-household')

  switchHousehold(householdToUse)
})
