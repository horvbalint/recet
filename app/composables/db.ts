import { applyDiagnostics, createRemoteEngines, DateTime, FileRef, RecordId, Surreal } from 'surrealdb'

export { surql } from 'surrealdb'

export const db = new Surreal({
  codecOptions: {
    valueDecodeVisitor(value) {
      const isBuiltInType = value instanceof RecordId || value instanceof DateTime || value instanceof FileRef

      if (isBuiltInType)
        return markRaw(value)
      else
        return value
    },
  },
  // engines: applyDiagnostics(createRemoteEngines(), (event) => {
  //   if (event.type === 'query' && event.phase === 'after')
  //     console.log(event.success, event.result.query, event.result.params)
  // }),
})
