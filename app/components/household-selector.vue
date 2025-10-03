<script setup lang="ts">
import type { Menu } from '@nebula/components/overlays/neb-menu.vue'
import type { OutHousehold } from '~/db'

const showCreateModal = ref(false)

const { data, refresh } = householdQuery.value!

async function handleHouseholdCreated(household: OutHousehold) {
  await refresh()
  switchHousehold(household)
}

const menus = computed(() => {
  const menus: Menu[] = data.map(household => ({
    text: household.name,
    icon: 'material-symbols:home-outline-rounded',
    callback: () => switchHousehold(household),
  }))

  menus.push({
    segment: true,
    text: 'Create Household',
    icon: 'material-symbols:add-rounded',
    callback: () => showCreateModal.value = true,
  })

  return menus
})
</script>

<template>
  <neb-menu full-width :menus>
    <template #trigger="{ toggle }">
      <neb-button
        class="household-button"
        type="secondary-neutral"
        full-width
        @click="toggle()"
      >
        <div class="label">
          <icon name="material-symbols:home-outline-rounded" />
          {{ currentHousehold?.name || 'Select Household' }}
        </div>
        <icon name="material-symbols:keyboard-arrow-down-rounded" />
      </neb-button>
    </template>
  </neb-menu>

  <household-modal
    v-model="showCreateModal"
    @created="handleHouseholdCreated($event)"
  />
</template>

<style scoped>
.household-button {
  justify-content: space-between;
  align-items: center;
  gap: var(--space-2);

  .label {
    display: flex;
    align-items: center;
    gap: var(--space-2);
  }
}
</style>
