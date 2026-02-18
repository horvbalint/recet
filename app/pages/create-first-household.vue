<script setup lang="ts">
const householdName = ref('')
const isCreating = ref(false)

async function createAndNavigate() {
  try {
    isCreating.value = true

    const household = await createHousehold(householdName.value.trim())
    switchHousehold(household)

    useNebToast({ type: 'success', title: 'Household created', description: `Welcome to ${household.name}!` })

    await navigateTo('/')
  }
  catch (err) {
    console.error('Error creating household:', err)
    useNebToast({ type: 'error', title: 'Creation failed', description: 'Could not create household.' })
  }
  finally {
    isCreating.value = false
  }
}
</script>

<template>
  <div class="onboarding-page">
    <div class="onboarding-container">
      <div class="onboarding-card">
        <div class="onboarding-header">
          <div class="header-icon">
            <icon name="material-symbols:home-outline-rounded" />
          </div>

          <neb-content-header
            title="Create Your First Household"
            description="Welcome! Let's set up your household to start managing recipes and shopping lists together."
            type="section"
          />
        </div>

        <div class="onboarding-form">
          <div class="form-fields">
            <neb-input
              v-model="householdName"
              label="Household Name"
              placeholder="e.g., The Smith Family, Our Home"
              :required="true"
              @keyup.enter="createAndNavigate()"
            />
          </div>

          <div class="form-actions">
            <neb-button
              type="primary"
              class="submit-button"
              :loading="isCreating"
              :disabled="!householdName.trim() || isCreating"
              @click="createAndNavigate()"
            >
              <icon name="material-symbols:add-home-outline-rounded" />
              Create Household
            </neb-button>

            <div class="onboarding-note">
              You can invite family members later
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.onboarding-page {
  min-height: 100vh;
  background: var(--neutral-color-25);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-6);
}

.onboarding-container {
  width: 100%;
  max-width: 420px;
}

.onboarding-card {
  background: #fff;
  border-radius: var(--radius-large);
  border: 1px solid var(--neutral-color-100);
  box-shadow: var(--shadow-lg);
  padding: var(--space-8);
}

.onboarding-header {
  text-align: center;
  margin-bottom: var(--space-8);
}

.header-icon {
  margin: 0 auto var(--space-4);
  width: 64px;
  height: 64px;
  background: linear-gradient(135deg, var(--primary-color-400), var(--primary-color-500));
  border-radius: var(--radius-large);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: var(--shadow-md);

  .icon {
    font-size: 34px !important;
    color: white;
  }
}

.header-icon :deep(svg) {
  color: white;
  width: 32px;
  height: 32px;
}

.onboarding-form {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.form-fields {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.form-actions {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.submit-button {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
}

.onboarding-note {
  text-align: center;
  font-size: var(--text-sm);
  color: var(--neutral-color-500);
}

@media (--mobile-lg-viewport) {
  .onboarding-page {
    padding: var(--space-4);
  }

  .onboarding-card {
    padding: var(--space-6);
  }
}

.dark-mode {
  .onboarding-card {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);
  }

  .onboarding-note {
    color: var(--neutral-color-400);
  }
}
</style>
