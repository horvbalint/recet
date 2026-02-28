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

const tokenKey = 'recet_tokens'

db.subscribe('auth', (tokens) => {
  if (tokens)
    localStorage.setItem(tokenKey, JSON.stringify(tokens))
})

const userAccess = useAppBreakpoints().isMobile.value ? 'mobile_user' : 'desktop_user'
export async function signUp(email: string, username: string, password: string) {
  await db.signup({
    access: userAccess,
    variables: {
      email,
      username,
      password,
    },
  })
}

export async function signIn(email: string, password: string) {
  await db.signin({
    access: userAccess,
    variables: {
      email,
      password,
    },
  })

  authUser.value = await db.auth<OutUser>() || null
}

export async function authenticateWithToken() {
  const tokens = localStorage.getItem(tokenKey)
  if (!tokens)
    return

  await db.authenticate(JSON.parse(tokens))
}

export function logout() {
  authUser.value = null
  db.invalidate()
}
