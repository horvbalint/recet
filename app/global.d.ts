import type { DateTime, FileRef, RecordId } from 'surrealdb'

declare module '@vue/reactivity' {
  export interface RefUnwrapBailTypes {
    RecordId: RecordId
    DateTime: DateTime
    FileRef: FileRef
  }
}

export {}
