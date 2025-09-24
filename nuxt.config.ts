// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  ssr: false,
  compatibilityDate: '2025-07-15',
  extends: ['nebula'],
  modules: ['@nuxtjs/color-mode'],

  runtimeConfig: {
    public: {
      surrealDbUrl: 'ws://localhost:8000/rpc',
    },
  },

  app: {
    head: {
      title: 'Recet',
    },
  },

  routeRules: {
    '**': {
      appMiddleware: ['auth', 'household'],
    },
    '/create-first-household': {
      appMiddleware: {
        household: false,
      },
    },
    '/auth/**': {
      appMiddleware: {
        auth: false,
        household: false,
      },
    },
  },

  css: ['@/assets/main.css'],

  nebula: {
    primaryColor: '#BE2577',
  },

  colorMode: {
    preference: 'system',
  },

  i18n: {
    defaultLocale: 'en',
    detectBrowserLanguage: false,
  },

  devtools: { enabled: true },
})
