import type { RecordId } from 'surrealdb'
import type { OutMember, OutUser } from '~/db'

export default defineNuxtRouteMiddleware(async () => {
  try {
    if (authUser.value)
      return

    if (localStorage.recet_token)
      await db.authenticate(localStorage.recet_token)

    authUser.value = await db.info<OutUser>() || null
    const [memberships] = await db.query<[{ out: RecordId<'household'>, role: OutMember['role'] }[]]>(surql`SELECT out, role FROM member WHERE in = $auth.id`)
    authMemberships.value = new Map(memberships.map(m => [m.out.toString(), m.role]))

    if (!authUser.value)
      throw new Error('Not authenticated')
  }
  catch (err) {
    console.error(err)
    return navigateTo('/auth/login')
  }
})
