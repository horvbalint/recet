import type { OutHousehold } from '~/db'

export default defineNuxtRouteMiddleware(async () => {
  householdQuery.value = householdQuery.value || await useAsyncData(async () => {
    const [households] = await db
      .query(surql`$auth.id -> member.out.{ id, name, language };`)
      .collect<[OutHousehold[]]>()
    return households
  })

  if (householdQuery.value?.error)
    throw createError({ message: householdQuery.value.error.message, cause: householdQuery.value.error })

  const stored = localStorage.getItem('currentHousehold')
  const sameId = householdQuery.value!.data.find(h => h.id.toString() === stored)

  const householdToUse = sameId ?? householdQuery.value!.data[0]
  if (!householdToUse)
    return navigateTo('/create-first-household')

  switchHousehold(householdToUse)
})
