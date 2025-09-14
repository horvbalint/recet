import type { OutUser } from "~/db"

export default defineNuxtRouteMiddleware(async (to, from) => {
  try {
    if(authUser.value)
      return

    if(localStorage['recet_token'])
      await db.authenticate(localStorage['recet_token'])

    authUser.value = await db.info<OutUser>() || null

    if (!authUser.value)
      throw new Error('Not authenticated')
  }
  catch(err) {
    console.error(err)
    return navigateTo('/auth/login' )
  }
})