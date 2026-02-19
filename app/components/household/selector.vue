<script setup lang="ts">
import type { Menu } from '@nebula/components/overlays/neb-menu.vue'
import type { OutHousehold } from '~/db'

const showCreateModal = ref(false)
const showJoinModal = ref(false)
const joinToken = ref('')
const isJoining = ref(false)

const { data, refresh } = householdQuery.value!

async function handleHouseholdCreated(household: OutHousehold) {
  await refresh()
  switchHousehold(household)
}

async function handleJoinHousehold() {
  if (!joinToken.value.trim())
    return

  isJoining.value = true
  try {
    const household = await joinHousehold(joinToken.value.trim())

    await refresh()
    switchHousehold(household)

    useNebToast({ type: 'success', title: 'Household joined!', description: `You are now a member of ${household.name}.` })
    showJoinModal.value = false
  }
  catch (error: any) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Failed to join', description: error.message || 'Invalid invitation token.' })
  }
  finally {
    isJoining.value = false
  }
}

watch(showJoinModal, (visible) => {
  if (visible)
    joinToken.value = ''
})

const menus = computed(() => {
  const menus: Menu[] = data.map(household => ({
    text: household.name,
    icon: 'material-symbols:home-outline-rounded',
    callback: () => switchHousehold(household),
  }))

  menus.push({
    segment: true,
    text: 'Join Household',
    icon: 'material-symbols:group-add-outline-rounded',
    callback: () => showJoinModal.value = true,
  })

  menus.push({
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

  <neb-modal v-model="showJoinModal" title="Join Household" header-icon="material-symbols:group-add-outline-rounded" max-width="450px">
    <template #content>
      <neb-input
        v-model="joinToken"
        label="Invitation Token"
        placeholder="Paste the invitation token"
        :disabled="isJoining"
        @keyup.enter="handleJoinHousehold()"
      />
    </template>

    <template #actions>
      <neb-button type="secondary" @click="showJoinModal = false">
        Cancel
      </neb-button>

      <neb-button type="primary" :disabled="!joinToken.trim() || isJoining" :loading="isJoining" @click="handleJoinHousehold()">
        Join
      </neb-button>
    </template>
  </neb-modal>
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
