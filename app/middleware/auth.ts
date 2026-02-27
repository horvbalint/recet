import type { RecordId } from 'surrealdb'
import type { OutMember, OutUser } from '~/db'

export default defineNuxtRouteMiddleware(async (to) => {
  try {
    if (authUser.value)
      return

    await authenticateWithToken()

    authUser.value = await db.auth<OutUser>() || null
    const [memberships] = await db
      .query(surql`SELECT out, role FROM member WHERE in = $auth`)
      .collect<[{ out: RecordId<'household'>, role: OutMember['role'] }[]]>()

    authMemberships.value = new Map(memberships.map(m => [m.out.toString(), m.role]))

    if (!authUser.value)
      throw new Error('Not authenticated')
  }
  catch (err) {
    console.error(err)
    return navigateTo(`/auth/login?to=${encodeURIComponent(to.path)}`)
  }
})
