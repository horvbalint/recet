import type { RecordId } from 'surrealdb'

export const { isMobile } = useAppBreakpoints()
export const pageHeaderType = computed(() => isMobile.value ? 'section' : 'page')

export function logOnError(error: Ref<any>) {
  watch(error, (err) => {
    if (err)
      console.error(err)
  })
}

export function transformId<T extends string>(id: RecordId<T>) {
  return id.toString()
}
