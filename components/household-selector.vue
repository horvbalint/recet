<script setup lang="ts">
import type { OutHousehold } from '~/db'

const showCreateModal = ref(false)
const { data, refresh, error } = useAsyncData(async () => {
  const [households] = await db.query<[OutHousehold[]]>(surql`
    ${authUser.value!.id} -> member -> household.{ id, name }
  `)

  return households
})

watchOnce(data, () => {
  const stored = localStorage.getItem('currentHousehold')
  const sameId = data.value?.find(h => h.id.toString() === stored)
  if (sameId)
    switchHousehold(sameId)
})

async function handleHouseholdCreated(household: OutHousehold) {
  await refresh()
  switchHousehold(household)
}
</script>

<template>
  <neb-dropdown full-width>
    <template #trigger="{ toggle }">
      <neb-button
        type="secondary"
        full-width
        class="household-button"
        @click="toggle()"
      >
        <div class="label">
          <icon name="material-symbols:home-rounded" />
          {{ currentHousehold?.name || 'Select Household' }}
        </div>
        <icon name="material-symbols:keyboard-arrow-down-rounded" />
      </neb-button>
    </template>

    <template #content="{ close }">
      <div class="household-dropdown">
        <div v-if="data!.length">
          <neb-button
            v-for="household in data"
            :key="household.id.toString()"
            type="tertiary"
            small
            full-width
            class="household-button"
            :class="{ active: currentHousehold?.id?.toString() === household.id.toString() }"
            @click="() => { switchHousehold(household); close(); }"
          >
            <div class="label">
              <icon name="material-symbols:home-rounded" />
              <span>{{ household.name }}</span>
            </div>
            <icon
              v-if="currentHousehold?.id?.toString() === household.id.toString()"
              name="material-symbols:check-rounded"
            />
          </neb-button>
        </div>

        <div class="household-footer">
          <neb-button
            type="tertiary"
            small
            full-width
            @click="() => { showCreateModal = true; close(); }"
          >
            <icon name="material-symbols:add-rounded" />
            Create Household
          </neb-button>
        </div>
      </div>
    </template>
  </neb-dropdown>

  <household-modal
    v-model="showCreateModal"
    @created="handleHouseholdCreated($event)"
  />
</template>

<style scoped>
.household-dropdown {
  max-height: 300px;
  overflow-y: auto;
  background: #fff;
  border: 1px solid var(--neutral-color-200);
  border-radius: var(--radius-default);
  box-shadow: var(--shadow-lg);
  padding: var(--space-1);
}

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

.household-footer {
  padding-top: var(--space-1);
  border-top: 1px solid var(--neutral-color-100);
  margin-top: var(--space-1);
}

.dark-mode {
  .household-dropdown {
    background: var(--neutral-color-800);
    border-color: var(--neutral-color-700);
  }

  .household-footer {
    border-color: var(--neutral-color-700);
  }
}
</style>
