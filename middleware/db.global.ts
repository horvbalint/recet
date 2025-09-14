export default defineNuxtRouteMiddleware(async () => {
  if(db.status === 'connected')
    return

  if(db.status === 'disconnected' || db.status === 'error')
    await db.connect("http://localhost:8000/rpc");

  await db.ready

  await db.use({
    namespace: "recet",
    database: "recet"
  });
})