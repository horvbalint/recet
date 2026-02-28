import type { DateTime, FileRef, RecordId } from 'surrealdb'

declare module '@vue/reactivity' {
  export interface RefUnwrapBailTypes {
    RecordId: RecordId
    DateTime: DateTime
    FileRef: FileRef
  }
}

declare global {
  type Optional<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>
}

export {}
