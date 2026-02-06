export default defineNuxtRouteMiddleware(async () => {
  if (db.status === 'connected')
    return

  if (db.status === 'disconnected')
    await db.connect(useRuntimeConfig().public.surrealDbUrl)

  await db.ready

  await db.use({
    namespace: 'recet',
    database: 'recet',
  })
})
