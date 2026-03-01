export default defineNuxtRouteMiddleware(async () => {
  if (db.status === 'connected')
    return

  if (db.status === 'disconnected') {
    await db.connect(useRuntimeConfig().public.surrealDbUrl, {
      reconnect: {
        enabled: true,
        attempts: 10,
        retryDelay: 100,
        retryDelayMax: 2000,
        retryDelayMultiplier: 2,
        retryDelayJitter: 0,
      },
    })
  }

  await db.ready

  await db.use({
    namespace: 'recet',
    database: 'recet',
  })
})
