// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  ssr: false,
  compatibilityDate: '2025-07-15',
  extends: ['nebula'],
  modules: ['@nuxtjs/color-mode', '@vite-pwa/nuxt'],

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

  css: [
    '@/assets/main.css',
    '@/assets/view-transitions.css',
  ],

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

  pwa: {
    client: {
      installPrompt: true,
    },
    manifest: {
      name: 'Recet',
      short_name: 'Recet',
      description: 'A recipe manager for your household',
      theme_color: '#BE2577',
      start_url: '/',
      shortcuts: [
        {
          name: 'Add recipe',
          description: 'Add a new recipe',
          url: '/recipe/create',
          icons: [{ src: 'add-recipe.png', sizes: '192x192', type: 'image/png' }],
        },
        {
          name: 'Shopping lists',
          description: 'View your shopping lists',
          url: '/shopping-lists',
          icons: [{ src: 'shopping-list.png', sizes: '192x192', type: 'image/png' }],
        },
      ],
      icons: [
        {
          src: 'pwa-64x64.png',
          sizes: '64x64',
          type: 'image/png',
        },
        {
          src: 'pwa-192x192.png',
          sizes: '192x192',
          type: 'image/png',
        },
        {
          src: 'pwa-512x512.png',
          sizes: '512x512',
          type: 'image/png',
        },
        {
          src: 'maskable-icon-512x512.png',
          sizes: '512x512',
          type: 'image/png',
          purpose: 'maskable',
        },
      ],
      screenshots: [
        {
          src: 'screenshots/recipes-desktop.png',
          label: 'The recipes page on a desktop screen',
          form_factor: 'wide',
          sizes: '1289x780',
        },
        {
          src: 'screenshots/recipes-mobile.png',
          label: 'The recipes page on a mobile screen',
          form_factor: 'narrow',
          sizes: '402x869',
        },
        {
          src: 'screenshots/recipe-desktop.png',
          label: 'The recipe page on a desktop screen',
          form_factor: 'wide',
          sizes: '1289x780',
        },
        {
          src: 'screenshots/recipe-mobile.png',
          label: 'The recipe page on a mobile screen',
          form_factor: 'narrow',
          sizes: '402x869',
        },
        {
          src: 'screenshots/master-data-desktop.png',
          label: 'The master data page on a desktop screen',
          form_factor: 'wide',
          sizes: '1289x780',
        },
        {
          src: 'screenshots/master-data-mobile.png',
          label: 'The master data page on a mobile screen',
          form_factor: 'narrow',
          sizes: '402x869',
        },
      ],
    },
    workbox: {
      skipWaiting: true,
    },
    devOptions: {
      enabled: true,
    },
  },

  devtools: { enabled: true },
})
