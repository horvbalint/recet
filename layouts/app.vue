<script setup lang="ts">
// Navigation structure based on wireframe
const navigationGroups = [
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
    items: [
      { id: 'members', name: 'Members', path: '/members', icon: 'material-symbols:group-outline-rounded' },
      { id: 'settings', name: 'Settings', path: '/settings', icon: 'material-symbols:settings-outline-rounded' },
    ],
  },
  {
    title: 'Data',
    items: [
      { id: 'master-data', name: 'Master Data', path: '/masterData', icon: 'material-symbols:category-outline-rounded' },
    ],
  },
]

const route = useRoute()
const currentPath = computed(() => route.path)

function isActive(path: string): boolean {
  if (path === '/') {
    return currentPath.value === '/'
  }
  return currentPath.value.startsWith(path)
}

const isMobileMenuOpen = ref(false)
</script>

<template>
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
            <icon name="material-symbols:restaurant-rounded" class="brand-icon" />
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
      </aside>

      <div class="main-area">
        <header class="top-bar">
          <neb-button
            type="tertiary-neutral"
            size="small"
            class="mobile-menu-button"
            @click="isMobileMenuOpen = true"
          >
            <icon name="material-symbols:menu-rounded" />
          </neb-button>
        </header>

        <main class="main-area-content">
          <div class="content-header-area">
            <slot name="content-header" />
          </div>

          <div class="main-content">
            <slot />
          </div>
        </main>
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

/* Sidebar Styles */
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
  transition: transform 0.3s ease;
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
  padding: 16px 24px;
  border-bottom: 1px solid var(--neutral-color-200);
  align-items: center;
  gap: 16px;
  min-height: 72px;
}

.mobile-menu-button {
  display: none;
}

.main-area-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: var(--space-6) 0 0;
}

.content-header-area {
  width: 100%;
  padding: 0 var(--space-6) var(--space-6);
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 var(--space-6) var(--space-6);
  width: 100%;
}

/* Mobile Styles */
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

  .main-area-content {
    padding-top: var(--space-4);
  }

  .content-header-area {
    padding: 0 var(--space-4) var(--space-4);
  }

  .main-content {
    padding: 0 var(--space-4) var(--space-4);
  }

  .mobile-menu-button {
    display: flex;
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

/* Dark mode support */
.dark-mode .sidebar {
  background: var(--neutral-color-950);
  border-color: var(--neutral-color-800);
  box-shadow: none;
}

.dark-mode .brand-text {
  color: white;
  border-bottom-color: var(--neutral-color-800);
}

.dark-mode .nav-group-title {
  color: var(--neutral-color-400);
}

.dark-mode .nav-item {
  color: var(--neutral-color-300);
}

.dark-mode .nav-item:hover {
  background: var(--neutral-color-800);
  color: white;
}

.dark-mode .nav-item.active {
  background: var(--primary-color-600);
  color: white;
}

.dark-mode .top-bar {
  background: var(--neutral-color-900);
  border-color: var(--neutral-color-800);
}
</style>
