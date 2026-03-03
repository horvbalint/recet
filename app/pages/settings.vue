<script setup lang="ts">
import type { InHousehold, OutHousehold } from '~/db'

const { t } = useI18n()

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

    useNuxtApp().$i18n.setLocale(result.language)

    useNebToast({ type: 'success', title: t('settings.success.title'), description: t('settings.success.description') })
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: t('settings.error.title'), description: t('settings.error.description') })
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
        :title="$t('settings.title')"
        :description="$t('settings.description')"
        :type="pageHeaderType"
        has-separator
      />
    </template>

    <div class="settings-page">
      <neb-content-header :title="$t('settings.general')" type="section" />

      <neb-validator v-model="isFormValid">
        <div class="form-content">
          <div class="flex-wrapper">
            <neb-input
              v-model="householdForm.name"
              :label="$t('settings.name.label')"
              :placeholder="$t('settings.name.placeholder')"
              required
            />

            <neb-select
              v-model="householdForm.language"
              :options="availableLanguages"
              label-key="name"
              track-by-key="code"
              use-only-tracked-key
              :label="$t('settings.language')"
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
          {{ $t('common.saveChanges') }}
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
