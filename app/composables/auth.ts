import type { OutMember, OutUser } from '~/db'

export type MemberShips = Map<string, OutMember['role']>

export const authUser = ref<OutUser | null>(null)
export const authMemberships = ref<MemberShips | null>(null)

export const currHouseholdRole = computed(() => {
  if (!currentHousehold.value || !authMemberships.value)
    return false
  return authMemberships.value.get(currentHousehold.value.id.toString())
})

export const isCurrHouseholdOwner = computed(() => currHouseholdRole.value === 'owner')
export const isCurrHouseholdEditor = computed(() => ['owner', 'writer'].includes(currHouseholdRole.value || ''))
export const isCurrHouseholdViewer = computed(() => ['owner', 'writer', 'guest'].includes(currHouseholdRole.value || ''))

export async function signUp(email: string, username: string, password: string) {
  const { access } = await db.signup({
    access: 'user',
    variables: {
      email,
      username,
      password,
    },
  })

  localStorage.setItem('recet_token', access)
}

export async function signIn(email: string, password: string) {
  const { access } = await db.signin({
    access: 'user',
    variables: {
      email,
      password,
    },
  })

  localStorage.setItem('recet_token', access)
}

export function logout() {
  authUser.value = null
  db.invalidate()
}
