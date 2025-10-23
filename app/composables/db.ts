import { DateTime, RecordId, Surreal } from 'surrealdb'

export { surql } from 'surrealdb'

export const db = new Surreal({
  codecOptions: {
    valueDecodeVisitor(value) {
      const isBuiltInType = value instanceof RecordId || value instanceof DateTime

      if (isBuiltInType)
        return markRaw(value)
      else
        return value
    },
  },
})
