import type { RecordId } from 'surrealdb'

export const { isMobile } = useAppBreakpoints()
export const pageHeaderType = computed(() => isMobile.value ? 'section' : 'page')

export function logOnError(error: Ref<any>) {
  watch(error, (err) => {
    if (err)
      console.error(err)
  })
}

export function compareIds<T extends string>(a: RecordId<T>, b: RecordId<T>) {
  return a.id === b.id
}
