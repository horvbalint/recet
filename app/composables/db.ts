import { applyDiagnostics, createRemoteEngines, Surreal, Value } from 'surrealdb'

export { surql } from 'surrealdb'

export const db = new Surreal({
  codecOptions: {
    valueDecodeVisitor(value) {
      if (value instanceof Value)
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
