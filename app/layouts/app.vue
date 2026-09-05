<script setup lang="ts">
import type { Menu } from '@nebula/components/overlays/neb-menu.vue'

const { t } = useI18n()
const navigationGroups = computed(() => {
  const householdItems = [
    { id: 'members', name: t('nav.members'), path: '/members', icon: 'material-symbols:group-outline-rounded' },
  ]

  if (isCurrHouseholdOwner.value)
    householdItems.push({ id: 'settings', name: t('nav.settings'), path: '/settings', icon: 'material-symbols:settings-outline-rounded' })

  const planningItems = [
    { id: 'recipes', name: t('nav.recipes'), path: '/', icon: 'material-symbols:menu-book-2-outline-rounded' },
  ]

  if (isCurrHouseholdEditor.value) {
    planningItems.push(
      { id: 'meal-planner', name: t('nav.mealPlanner'), path: '/meal-planner', icon: 'material-symbols:calendar-month-outline-rounded' },
      { id: 'shopping-lists', name: t('nav.shoppingLists'), path: '/shopping-lists', icon: 'material-symbols:shopping-cart-outline-rounded' },
    )
  }

  return [
    {
      title: t('nav.groups.planning'),
      items: planningItems,
    },
    {
      title: t('nav.groups.household'),
      items: householdItems,
    },
    {
      title: t('nav.groups.data'),
      items: [
        { id: 'master-data', name: t('nav.masterData'), path: '/master-data', icon: 'material-symbols:category-outline-rounded' },
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

const userMenus = computed<Menu[]>(() => [
  { text: t('nav.signOut'), icon: 'material-symbols:logout-rounded', callback: () => logout(), desctructive: true },
])
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
          :title="$t('nav.pwa.newVersion.tooltip.title')"
          :text="$t('nav.pwa.newVersion.tooltip.text')"
        >
          <neb-button type="link" full-width :disabled="installing" :loading="installing" @click="update()">
            {{ $t('nav.pwa.newVersion.button') }}
          </neb-button>
        </neb-tooltip>

        <neb-tooltip
          v-else-if="$pwa?.showInstallPrompt"
          class="pwa-button"
          :title="$t('nav.pwa.install.tooltip.title')"
          :text="$t('nav.pwa.install.tooltip.text')"
        >
          <neb-button type="link" full-width :disabled="installing" :loading="installing" @click="install()">
            {{ $t('nav.pwa.install.button') }}
          </neb-button>
        </neb-tooltip>

        <div class="sidebar-footer">
          <neb-menu full-width :menus="userMenus" :floating-options="{ placement: 'top-start' }">
            <template #trigger="{ toggle }">
              <neb-button class="user-button" type="tertiary-neutral" full-width @click="toggle()">
                <div class="label">
                  <icon name="material-symbols:account-circle-outline" />
                  <span class="username">{{ authUser?.username }}</span>
                </div>
                <icon name="material-symbols:keyboard-arrow-up-rounded" />
              </neb-button>
            </template>
          </neb-menu>
        </div>
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
            <div v-if="$pwa?.needRefresh || $pwa?.showInstallPrompt" class="indicator-dot" />
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
  background: var(--neb-bg-page);
}

.sidebar {
  width: 280px;
  background: var(--neb-bg-raised);
  color: var(--neb-text);
  display: flex;
  flex-direction: column;
  border-right: 1px solid var(--neb-border-subtle);
  position: fixed;
  height: 100vh;
  left: 0;
  top: 0;
  z-index: 100;
  transition: transform var(--duration-default) ease;
  box-shadow: var(--neb-shadow-lg);
}

.sidebar-header {
  padding: 24px 20px;
  border-bottom: 1px solid var(--neb-border-subtle);
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 20px;
}

.brand-icon {
  font-size: 32px !important;
  color: var(--primary-color);
}

.brand-text {
  font-size: 24px;
  font-weight: 700;
  color: var(--neb-text);
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
  color: var(--neb-text-muted);
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
  color: var(--neb-text-muted);
  text-decoration: none;
  transition: all 0.2s ease;
  border-radius: 0;
  position: relative;
}

.nav-item:hover {
  background: var(--neb-bg-active);
  color: var(--neb-text);
}

.nav-item.active {
  background: var(--neb-bg-selected);
  color: var(--neb-text-primary);
  /* border-right: 3px solid var(--neb-text-primary); */
}

.nav-item.active::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  height: 100%;
  width: 3px;
  background: var(--neb-text-primary);
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
  background: var(--neb-bg-raised);
  padding: var(--space-2) var(--space-3);
  border-bottom: 1px solid var(--neb-border-subtle);
  align-items: center;
  gap: 16px;
}

.mobile-menu-button {
  display: none;
}

.pwa-button {
  margin: var(--space-4);
}

.sidebar-footer {
  padding: var(--space-4);
  border-top: 1px solid var(--neb-border-subtle);
}

.user-button {
  justify-content: space-between;
  align-items: center;
  gap: var(--space-2);

  .label {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    min-width: 0;
  }

  .username {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
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
      border: 2px solid var(--neb-bg-raised);
      background: var(--neb-bg-primary-solid);
      border-radius: 50%;
    }
  }

  .mobile-backdrop {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: var(--neb-bg-backdrop);
    z-index: 99;
  }
}
</style>
