import type { OutHousehold } from '~/db'

export const currentHousehold = ref<OutHousehold | null>(null)

// Create a new household
export async function createHousehold(name: string) {
  if (!authUser.value) {
    throw new Error('Must be logged in to create household')
  }

  try {
    const [result] = await db.query<[OutHousehold]>(surql`
      CREATE household SET name = ${name}
    `)

    if (result) {
      // Set as current household if user doesn't have one
      if (!currentHousehold.value) {
        currentHousehold.value = result
      }

      return result
    }

    throw new Error('Failed to create household')
  }
  catch (error) {
    console.error('Error creating household:', error)
    throw error
  }
}

// Switch current household
export function switchHousehold(household: OutHousehold) {
  currentHousehold.value = household
  localStorage.setItem('currentHousehold', JSON.stringify(household))
}

// Initialize household state from localStorage
const stored = localStorage.getItem('currentHousehold')
if (stored) {
  try {
    currentHousehold.value = JSON.parse(stored)
  }
  catch {
    localStorage.removeItem('currentHousehold')
  }
}
