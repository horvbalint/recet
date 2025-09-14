// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  ssr: false,

  compatibilityDate: '2025-07-15',
  extends: ['nebula'],

  routeRules: {
    '**': {
      appMiddleware: ['auth'],
    },
    '/auth/**': {
      appMiddleware: {
        auth: false,
      },
    },
  },

  nebula: {
    primaryColor: '#BE2577',
  },

  i18n: {
    defaultLocale: 'en',
    detectBrowserLanguage: false,
  },

  devtools: { enabled: true },
  modules: ['@nuxtjs/color-mode'],
})
