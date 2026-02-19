import type { AsyncData } from '#app'
import type { OutHousehold } from '~/db'
import dayjs from 'dayjs'
import 'dayjs/locale/en'
import 'dayjs/locale/hu'

export const householdQuery = ref<Awaited<AsyncData<OutHousehold[], any>> | null>(null)

export const currentHousehold = ref<OutHousehold | null>(null)

export async function createHousehold(name: string) {
  try {
    const [result] = await db
      .query(surql`CREATE ONLY household SET name = ${name}`)
      .collect<[OutHousehold]>()
    if (!currentHousehold.value)
      currentHousehold.value = result

    return result
  }
  catch (error) {
    console.error('Error creating household:', error)
    throw error
  }
}

export async function joinHousehold(token: string) {
  const [result] = await db
    .query(surql`api::invoke("/invitation/accept", { method: 'post', body: { token: ${token} } })`)
    .collect<[{ status: number, body: any }]>()

  if (result.status !== 200)
    throw new Error(result.body.error || 'Failed to join household')

  const household = result.body as OutHousehold
  authMemberships.value?.set(household.id.toString(), 'guest')

  return household
}

export function switchHousehold(household: OutHousehold) {
  currentHousehold.value = household
  localStorage.setItem('currentHousehold', household.id.toString())
}

watch(currentHousehold, () => {
  dayjs.locale(currentHousehold.value?.language || 'en')
})
