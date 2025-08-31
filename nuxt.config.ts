// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  extends: ['nebula'],

  nebula: {
    primaryColor: '#BE2577'
  },

  devtools: { enabled: true },
  modules: ['@nuxtjs/color-mode']
})