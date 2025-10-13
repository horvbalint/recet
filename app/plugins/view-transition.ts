export default defineNuxtPlugin((nuxt) => {
  nuxt.hook('page:finish', () => {
    resolvePendingViewTransition()
  })
})
