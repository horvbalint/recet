<script setup lang="ts">
const navigationGroups = computed(() => {
  const householdItems = [
    { id: 'members', name: 'Members', path: '/members', icon: 'material-symbols:group-outline-rounded' },
  ]

  if (isCurrHouseholdOwner.value)
    householdItems.push({ id: 'settings', name: 'Settings', path: '/settings', icon: 'material-symbols:settings-outline-rounded' })

  return [
    {
      title: 'Planning',
      items: [
        { id: 'recipes', name: 'Recipes', path: '/', icon: 'material-symbols:menu-book-2-outline-rounded' },
        { id: 'meal-planner', name: 'Meal Planner', path: '/meal-planner', icon: 'material-symbols:calendar-month-outline-rounded' },
        { id: 'shopping-lists', name: 'Shopping Lists', path: '/shopping-lists', icon: 'material-symbols:shopping-cart-outline-rounded' },
      ],
    },
    {
      title: 'Household',
      items: householdItems,
    },
    {
      title: 'Data',
      items: [
        { id: 'master-data', name: 'Master Data', path: '/master-data', icon: 'material-symbols:category-outline-rounded' },
      ],
    },
  ]
})

const route = useRoute()
const currentPath = computed(() => route.path)

function isActive(path: string): boolean {
  if (path === '/') {
    return currentPath.value === '/'
  }
  return currentPath.value.startsWith(path)
}

const isMobileMenuOpen = ref(false)

const installing = ref(false)
function install() {
  installing.value = true
  useNuxtApp().$pwa?.install().finally(() => installing.value = false)
}

function update() {
  installing.value = true
  useNuxtApp().$pwa?.updateServiceWorker().finally(() => installing.value = false)
}
</script>

<template>
  <nuxt-pwa-assets />

  <nuxt-layout name="default">
    <div class="app-layout">
      <div
        v-if="isMobileMenuOpen"
        class="mobile-backdrop"
        @click="isMobileMenuOpen = false"
      />

      <aside
        class="sidebar"
        :class="{ 'mobile-open': isMobileMenuOpen }"
      >
        <div class="sidebar-header">
          <div class="brand">
            <icon name="material-symbols:chef-hat-outline-rounded" class="brand-icon" />
            <span class="brand-text">Recet</span>
          </div>

          <div class="household-section">
            <household-selector />
          </div>
        </div>

        <nav class="sidebar-nav">
          <div
            v-for="group in navigationGroups"
            :key="group.title"
            class="nav-group"
          >
            <div class="nav-group-title">
              {{ group.title }}
            </div>

            <div class="nav-items">
              <nuxt-link
                v-for="item in group.items"
                :key="item.id"
                :to="item.path"
                class="nav-item"
                :class="{ active: isActive(item.path) }"
                @click="isMobileMenuOpen = false"
              >
                <icon :name="item.icon" class="nav-icon" />
                <span class="nav-text">{{ item.name }}</span>
              </nuxt-link>
            </div>
          </div>
        </nav>

        <neb-tooltip
          v-if="$pwa?.needRefresh"
          class="pwa-button"
          title="There is a new version available."
          text="To update, click this button and wait for the page to reload."
        >
          <neb-button type="link" full-width :disabled="installing" :loading="installing" @click="update()">
            ✨ New version available ✨
          </neb-button>
        </neb-tooltip>

        <neb-tooltip
          v-else-if="$pwa?.showInstallPrompt"
          class="pwa-button"
          title="Install Recet as an app!"
          text="Click this button to install Recet on your device in an instant."
        >
          <neb-button type="link" full-width :disabled="installing" :loading="installing" @click="install()">
            ✨ Install with one click ✨
          </neb-button>
        </neb-tooltip>
      </aside>

      <div class="main-area">
        <header class="top-bar">
          <neb-button
            type="tertiary-neutral"
            small
            class="mobile-menu-button"
            @click="isMobileMenuOpen = true"
          >
            <icon name="material-symbols:menu-rounded" />
            <div v-if="true" class="indicator-dot" />
          </neb-button>
        </header>

        <slot />
      </div>
    </div>
  </nuxt-layout>
</template>

<style scoped>
.app-layout {
  display: flex;
  min-height: 100vh;
  background: var(--neutral-color-25);
}

.sidebar {
  width: 280px;
  background: white;
  color: var(--neutral-color-900);
  display: flex;
  flex-direction: column;
  border-right: 1px solid var(--neutral-color-200);
  position: fixed;
  height: 100vh;
  left: 0;
  top: 0;
  z-index: 100;
  transition: transform var(--duration-default) ease;
  box-shadow: var(--shadow-lg);
}

.sidebar-header {
  padding: 24px 20px;
  border-bottom: 1px solid var(--neutral-color-200);
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 20px;
}

.brand-icon {
  font-size: 32px !important;
  color: var(--primary-color-500);
}

.brand-text {
  font-size: 24px;
  font-weight: 700;
  color: var(--neutral-color-900);
}

.household-section {
  margin-top: 16px;
}

/* Navigation Styles */
.sidebar-nav {
  flex: 1;
  padding: 24px 0;
  overflow-y: auto;
}

.nav-group {
  margin-bottom: 32px;
}

.nav-group-title {
  padding: 0 20px 12px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  color: var(--neutral-color-500);
  letter-spacing: 0.5px;
}

.nav-items {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 20px;
  color: var(--neutral-color-600);
  text-decoration: none;
  transition: all 0.2s ease;
  border-radius: 0;
  position: relative;
}

.nav-item:hover {
  background: var(--neutral-color-100);
  color: var(--neutral-color-900);
}

.nav-item.active {
  background: var(--primary-color-50);
  color: var(--primary-color-700);
  border-right: 3px solid var(--accent-color-500);
}

.nav-item.active::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  height: 100%;
  width: 3px;
  background: var(--accent-color-500);
}

.nav-icon {
  font-size: 20px !important;
  flex-shrink: 0;
}

.nav-text {
  font-weight: 500;
  font-size: 14px;
}

/* Main Area Styles */
.main-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  margin-left: 280px;
  min-height: 100vh;
}

.top-bar {
  display: none;
  background: white;
  padding: var(--space-2) var(--space-3);
  border-bottom: 1px solid var(--neutral-color-200);
  align-items: center;
  gap: 16px;
}

.mobile-menu-button {
  display: none;
}

.pwa-button {
  margin: var(--space-4);
}

@media (--tablet-viewport) {
  .top-bar {
    display: flex;
  }

  .sidebar {
    transform: translateX(-100%);
  }

  .sidebar.mobile-open {
    transform: translateX(0);
  }

  .main-area {
    margin-left: 0;
  }

  .mobile-menu-button {
    display: flex;
    position: relative;

    .indicator-dot {
      position: absolute;
      top: 9px;
      right: 10px;
      width: 10px;
      height: 10px;
      border: 2px solid white;
      background: var(--primary-color);
      border-radius: 50%;
    }
  }

  .mobile-backdrop {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    z-index: 99;
  }
}

.dark-mode {
  .sidebar {
    background: var(--neutral-color-950);
    border-color: var(--neutral-color-800);
    box-shadow: none;
  }

  .mobile-menu-button {
    .indicator-dot {
      border: 2px solid var(--neutral-color-900);
    }
  }

  .sidebar-header {
    border-bottom: 1px solid var(--neutral-color-800);
  }

  .brand-text {
    color: white;
    border-bottom-color: var(--neutral-color-800);
  }

  .nav-group-title {
    color: var(--neutral-color-400);
  }

  .nav-item {
    color: var(--neutral-color-300);

    &:hover {
      background: var(--neutral-color-800);
      color: white;
    }

    &.active {
      background: var(--primary-color-600);
      color: white;
    }
  }

  .top-bar {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);
  }
}
</style>
