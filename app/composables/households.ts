import type { OutHousehold } from '~/db'
import dayjs from 'dayjs'
import 'dayjs/locale/en'
import 'dayjs/locale/hu'

export const currentHousehold = ref<OutHousehold | null>(null)

const houseHoldQueryKey = 'member-households'
export const householdQuery = useAsyncData(houseHoldQueryKey, async () => {
  const [households] = await db
    .query(surql`SELECT VALUE out.{ id, name, language } FROM member WHERE in = $auth`)
    .collect<[OutHousehold[]]>()
  return households
}, {
  immediate: false,
  getCachedData: (key, nuxt) => nuxt.payload.data[key],
})

export async function createHousehold(name: string) {
  try {
    const [result] = await db
      .query(surql`CREATE ONLY household SET name = ${name}`)
      .collect<[OutHousehold]>()
    if (!currentHousehold.value)
      currentHousehold.value = result

    householdQuery.clear()

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

  householdQuery.clear()

  return household
}

export function switchHousehold(household: OutHousehold) {
  currentHousehold.value = household
  localStorage.setItem('currentHousehold', household.id.toString())
}

watch(currentHousehold, () => {
  dayjs.locale(currentHousehold.value?.language || 'en')
})
