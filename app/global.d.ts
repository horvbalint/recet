import type { Value } from 'surrealdb'

declare module '@vue/reactivity' {
  export interface RefUnwrapBailTypes {
    Value: Value
  }
}

declare global {
  type Optional<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>
}

export {}
