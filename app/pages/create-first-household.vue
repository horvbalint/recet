<script setup lang="ts">
const householdName = ref('')
const isCreating = ref(false)
const joinToken = ref('')
const isJoining = ref(false)

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

async function joinAndNavigate() {
  if (!joinToken.value.trim())
    return

  isJoining.value = true
  try {
    const household = await joinHousehold(joinToken.value.trim())
    switchHousehold(household)

    useNebToast({ type: 'success', title: 'Household joined!', description: `Welcome to ${household.name}!` })

    await navigateTo('/')
  }
  catch (error: any) {
    console.error('Error joining household:', error)
    useNebToast({ type: 'error', title: 'Failed to join', description: error.message || 'Invalid invitation token.' })
  }
  finally {
    isJoining.value = false
  }
}

const tabs = {
  create: 'Create a household',
  join: 'Join a household',
} as const
const selectedTab = ref<keyof typeof tabs>('create')
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
            title="First you need a household"
            description="Welcome! Let's set up your household to start managing recipes and shopping lists together."
            type="section"
          />
        </div>

        <neb-tabs v-model="selectedTab" full-width hierarchy="tertiary" :tabs />

        <div v-if="selectedTab === 'create'" class="onboarding-form">
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

            <neb-button type="link" @click="selectedTab = 'join'">
              or join a household
            </neb-button>
          </div>
        </div>

        <div v-else class="onboarding-form">
          <div class="form-fields">
            <neb-input
              v-model="joinToken"
              label="Invitation Token"
              placeholder="Paste the invitation token you received"
              :required="true"
              @keyup.enter="joinAndNavigate()"
            />
          </div>

          <div class="form-actions">
            <neb-button
              type="primary"
              class="submit-button"
              :loading="isJoining"
              :disabled="!joinToken.trim() || isJoining"
              @click="joinAndNavigate()"
            >
              <icon name="material-symbols:group-add-outline-rounded" />
              Join Household
            </neb-button>

            <neb-button type="link" @click="selectedTab = 'create'">
              or create a new household
            </neb-button>
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
  display: flex;
  flex-direction: column;
  gap: var(--space-8);
  background: #fff;
  border-radius: var(--radius-large);
  border: 1px solid var(--neutral-color-100);
  box-shadow: var(--shadow-lg);
  padding: var(--space-8);
}

.onboarding-header {
  text-align: center;
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
}
</style>
