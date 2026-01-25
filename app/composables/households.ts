import type { AsyncData } from '#app'
import type { OutHousehold } from '~/db'
import dayjs from 'dayjs'
import 'dayjs/locale/en'
import 'dayjs/locale/hu'

export const householdQuery = ref<Awaited<AsyncData<OutHousehold[], any>> | null>(null)

export const currentHousehold = ref<OutHousehold | null>(null)

// Create a new household
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

// Switch current household
export function switchHousehold(household: OutHousehold) {
  currentHousehold.value = household
  localStorage.setItem('currentHousehold', household.id.toString())
}

watch(currentHousehold, () => {
  dayjs.locale(currentHousehold.value?.language || 'en')
})
