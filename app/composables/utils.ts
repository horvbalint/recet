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

let resolveTransition: ((_: unknown) => void) | null = null
export function startTransitionThen(fun: () => any) {
  if (!document.startViewTransition) {
    fun()
  }
  else {
    document.startViewTransition(() => new Promise((resolve) => {
      resolveTransition = resolve
      fun()
    }))
  }
}
export function resolvePendingViewTransition() {
  if (resolveTransition) {
    resolveTransition(true)
    resolveTransition = null
  }
}

export function roundNumberIfNeeded(num: number) {
  if (Number.isInteger(num))
    return num
  else
    return Number(num.toFixed(1))
}
