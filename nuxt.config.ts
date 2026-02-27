// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  ssr: false,
  compatibilityDate: '2025-07-15',
  extends: ['nebula'],
  modules: ['@nuxtjs/color-mode', '@vite-pwa/nuxt'],

  runtimeConfig: {
    public: {
      surrealDbUrl: 'ws://localhost:8000',
    },
  },

  imports: {
    dirs: [
      '~/composables',
    ],
  },

  app: {
    head: {
      title: 'Recet',
    },
  },

  routeRules: {
    '**': {
      appMiddleware: ['auth', 'household'],
      appLayout: 'app',
    },
    '/create-first-household': {
      appMiddleware: {
        household: false,
      },
      appLayout: 'empty',
    },
    '/auth/**': {
      appMiddleware: {
        auth: false,
        household: false,
      },
      appLayout: 'empty',
    },
    '/public/recipe/*': {
      appMiddleware: {
        'auth': false,
        'household': false,
        'guest-auth': true,
      },
      appLayout: 'empty',
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
    classSuffix: '-mode',
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
          icons: [{
            src: 'icons/add-recipe.png',
            sizes: '192x192',
            type: 'image/png',
          }],
        },
        {
          name: 'Shopping lists',
          description: 'View your shopping lists',
          url: '/shopping-lists',
          icons: [{
            src: 'icons/shopping-list.png',
            sizes: '192x192',
            type: 'image/png',
          }],
        },
        {
          name: 'Meal planner',
          description: 'Plan for the days to come',
          url: '/meal-planner',
          icons: [{
            src: 'icons/meal-planner.png',
            sizes: '192x192',
            type: 'image/png',
          }],
        },
      ],
      icons: [
        {
          src: 'icons/pwa-64x64.png',
          sizes: '64x64',
          type: 'image/png',
        },
        {
          src: 'icons/pwa-192x192.png',
          sizes: '192x192',
          type: 'image/png',
        },
        {
          src: 'icons/pwa-512x512.png',
          sizes: '512x512',
          type: 'image/png',
        },
        {
          src: 'icons/maskable-icon-512x512.png',
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
    // devOptions: {
    //   enabled: true,
    // },
  },

  vite: {
    optimizeDeps: {
      include: [
        'blurhash',
        'browser-image-resizer',
        '@formkit/drag-and-drop/vue',
      ],
    },
  },

  devtools: { enabled: true },
})
