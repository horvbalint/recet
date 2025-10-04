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
          short_name: 'Add recipe',
          description: 'Add a new recipe',
          url: '/recipe/create',
          icons: [{ src: 'add-recipe.svg', sizes: 'any', type: 'image/svg+xml' }],
        },
        {
          name: 'Shopping lists',
          short_name: 'Shopping lists',
          description: 'View your shopping lists',
          url: '/shopping-lists',
          icons: [{ src: 'shopping-list.svg', sizes: 'any', type: 'image/svg+xml' }],
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
        {
          src: 'favicon.svg',
          sizes: 'any',
          type: 'image/svg+xml',
        },
      ],
    },
    workbox: {
      skipWaiting: true,
    },
    // devOptions: {
    //   enabled: true,
    // },
  },

  devtools: { enabled: true },
})
