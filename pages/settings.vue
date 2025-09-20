<script setup lang="ts">
import type { OutHousehold } from '~/db'

watch(isCurrHouseholdOwner, () => {
  if (!isCurrHouseholdOwner.value)
    navigateTo('/')
}, { immediate: true })

const householdForm = ref({
  name: currentHousehold.value!.name,
})

const isFormValid = ref(false)
const isLoading = ref(false)

async function handleSaveHousehold() {
  isLoading.value = true

  try {
    const [result] = await db.query<[OutHousehold]>(surql`UPDATE ONLY ${currentHousehold.value!.id} SET name = ${householdForm.value.name} RETURN AFTER`)
    currentHousehold.value = result

    useNebToast({ type: 'success', title: 'Household updated!', description: 'The household name has been successfully updated.' })
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Update failed!', description: 'Could not update the household name. Please try again.' })
  }
  finally {
    isLoading.value = false
  }
}
</script>

<template>
  <nuxt-layout name="app">
    <template #content-header>
      <neb-content-header
        title="Household Settings"
        description="Manage your household configuration and preferences"
        type="page"
        has-separator
      />
    </template>

    <div class="settings-page">
      <div class="settings-section">
        <neb-content-header title="General settings" type="section" />

        <neb-validator v-model="isFormValid">
          <div class="form-content">
            <neb-input
              v-model="householdForm.name"
              label="Household Name"
              placeholder="Enter household name"
              required
              :disabled="isLoading"
            />
          </div>
        </neb-validator>

        <div class="form-actions">
          <neb-button
            type="primary"
            :disabled="!isFormValid || isLoading"
            :loading="isLoading"
            @click="handleSaveHousehold()"
          >
            Save Changes
          </neb-button>
        </div>
      </div>

      <!-- Placeholder for future settings -->
      <div class="settings-section">
        <neb-content-header title="More settings" type="section" />

        <div class="placeholder-content">
          <p class="placeholder-text">
            Additional household settings will be added here in future updates.
          </p>
        </div>
      </div>
    </div>
  </nuxt-layout>
</template>

<style scoped>
.settings-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-8);
}

.settings-section {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
  padding: var(--space-6);
  background-color: var(--color-neutral-25);
  border-radius: var(--radius-large);
  border: 1px solid var(--color-neutral-200);
}

.form-content {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.form-actions {
  display: flex;
  gap: var(--space-3);
  justify-content: flex-end;
  padding-top: var(--space-4);
  border-top: 1px solid var(--color-neutral-200);
}

.placeholder-content {
  padding: var(--space-6);
  text-align: center;
  background-color: var(--color-neutral-50);
  border-radius: var(--radius-default);
  border: 1px dashed var(--color-neutral-300);
}

.placeholder-text {
  color: var(--color-neutral-600);
  font-style: italic;
  margin: 0;
}
</style>
