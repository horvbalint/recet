import type { OutUser } from '~/db'

export const authUser = ref<OutUser | null>(null)

export async function signUp(email: string, username: string, password: string) {
  const token = await db.signup({
    access: 'user',
    variables: {
      email,
      username,
      password,
    },
  })

  localStorage.setItem('recet_token', token)
}

export async function signIn(email: string, password: string) {
  const token = await db.signin({
    access: 'user',
    variables: {
      email,
      password,
    },
  })

  localStorage.setItem('recet_token', token)
}

export function logout() {
  authUser.value = null
  db.invalidate()
}
