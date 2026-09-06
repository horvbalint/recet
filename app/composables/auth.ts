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

// only desktop_user and mobile_user are WITH REFRESH, so a token without one belongs to a
// recipe_guest session: persisting it would overwrite the signed in user's refresh tokens
// and log them out of their own account just by opening a public recipe link
db.subscribe('auth', (tokens) => {
  if (tokens?.refresh)
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

export function hasStoredUserTokens() {
  return !!localStorage.getItem(tokenKey)
}

export async function authenticateWithToken() {
  const tokens = localStorage.getItem(tokenKey)
  if (!tokens)
    return

  await db.authenticate(JSON.parse(tokens))
}

export async function logout() {
  localStorage.removeItem(tokenKey)
  localStorage.removeItem(currentHouseholdKey)

  authUser.value = null
  authMemberships.value = null
  currentHousehold.value = null

  clearRecipeImageCache()
  resetList()
  householdQuery.clear()

  // every useAsyncData call caches by key in the payload, so without this the next user
  // signing in on the same tab would be served the previous one's recipes
  const cachedData = useNuxtApp().payload.data
  for (const key of Object.keys(cachedData))
    delete cachedData[key]

  await db.invalidate()
  await navigateTo('/auth/login')
}
