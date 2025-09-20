import type { AsyncData } from '#app'
import type { OutHousehold } from '~/db'
import { Gap } from 'surrealdb'

export const householdQuery = ref<AsyncData<OutHousehold[], any> | null>(null)

export const currentHousehold = ref<OutHousehold | null>(null)
export const householdGap = new Gap<OutHousehold['id']>()

// Create a new household
export async function createHousehold(name: string) {
  try {
    const [result] = await db.query<[OutHousehold]>(surql`
      CREATE ONLY household SET name = ${name}
    `)

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
