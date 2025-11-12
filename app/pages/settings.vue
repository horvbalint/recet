<script setup lang="ts">
import type { InHousehold, OutHousehold } from '~/db'

definePageMeta({
  layout: 'app',
})

watch(isCurrHouseholdOwner, () => {
  if (!isCurrHouseholdOwner.value)
    navigateTo('/')
}, { immediate: true })

const householdForm = ref<Omit<InHousehold, 'updated_at'>>({ ...currentHousehold.value! })

const isFormValid = ref(false)
const isLoading = ref(false)

async function handleSaveHousehold() {
  isLoading.value = true

  try {
    const [result] = await db
      .query(surql`UPDATE ONLY ${currentHousehold.value!.id} MERGE ${householdForm.value} RETURN AFTER`)
      .collect<[OutHousehold]>()
    currentHousehold.value = result

    useNebToast({ type: 'success', title: 'Household updated!', description: 'The household has been successfully updated.' })
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Update failed!', description: 'Could not update the household. Please try again.' })
  }
  finally {
    isLoading.value = false
  }
}

const availableLanguages = [
  { code: 'en', name: 'English' },
  { code: 'hu', name: 'Magyar' },
]
</script>

<template>
  <page-layout>
    <template #content-header>
      <neb-content-header
        title="Household Settings"
        description="Manage your household configuration and preferences"
        :type="pageHeaderType"
        has-separator
      />
    </template>

    <div class="settings-page">
      <neb-content-header title="General settings" type="section" />

      <neb-validator v-model="isFormValid">
        <div class="form-content">
          <div class="flex-wrapper">
            <neb-input
              v-model="householdForm.name"
              label="Household Name"
              placeholder="Enter household name"
              required
            />

            <neb-select
              v-model="householdForm.language"
              :options="availableLanguages"
              label-key="name"
              track-by-key="code"
              use-only-tracked-key
              label="Language"
              required
              no-search
              :allow-empty="false"
            />
          </div>
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
  </page-layout>
</template>

<style scoped>
.settings-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
  padding: var(--space-6);
  border-radius: var(--radius-large);
  border: 1px solid var(--neutral-color-200);
}

.form-content {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.flex-wrapper {
  display: flex;
  gap: var(--space-4);
  flex-wrap: wrap;

  & > * {
    flex: 1;
  }
}

.form-actions {
  display: flex;
  gap: var(--space-3);
  justify-content: flex-end;
  padding-top: var(--space-4);
}

@media (--tablet-viewport) {
  .flex-wrapper {
    flex-direction: column;
  }
}

.dark-mode {
  .settings-page {
    border: 1px solid var(--neutral-color-800);
  }
}
</style>
