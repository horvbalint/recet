<script setup lang="ts">
import { SurrealError } from 'surrealdb'

const formData = ref({
  username: '',
  email: '',
  password: '',
  confirmPassword: '',
})

const isFormValid = ref(false)

const { t } = useI18n()

async function handleSubmit() {
  if (formData.value.password !== formData.value.confirmPassword) {
    useNebToast({ type: 'error', title: t('auth.signup.passwordMismatch.title'), description: t('auth.signup.passwordMismatch.description') })
    return
  }

  try {
    await signUp(formData.value.email, formData.value.username, formData.value.password)

    useNebToast({ type: 'success', title: t('auth.signup.success.title'), description: t('auth.signup.success.description') })

    goToLogin()
  }
  catch (error) {
    console.error('Signup error:', error)

    if (error instanceof SurrealError)
      useNebToast({ type: 'error', title: t('auth.signup.error.title'), description: error.message })
    else
      useNebToast({ type: 'error', title: t('auth.signup.error.title'), description: t('auth.signup.error.description') })
  }
}

function goToLogin() {
  startTransitionThen(() => navigateTo('/auth/login'))
}
</script>

<template>
  <div class="auth-page">
    <div class="auth-card">
      <neb-content-header
        :title="$t('auth.signup.title')"
        :description="$t('auth.signup.description')"
        type="section"
      />

      <div class="auth-form">
        <neb-validator v-model="isFormValid">
          <div class="form-fields">
            <neb-input
              v-model="formData.username"
              :label="$t('auth.signup.username.label')"
              :placeholder="$t('auth.signup.username.placeholder')"
              required
            />

            <neb-input
              v-model="formData.email"
              :label="$t('auth.signup.email.label')"
              type="email"
              :placeholder="$t('auth.signup.email.placeholder')"
              required
              class="email-input"
            />

            <neb-input
              v-model="formData.password"
              :label="$t('auth.signup.password.label')"
              type="password"
              :placeholder="$t('auth.signup.password.placeholder')"
              required
              class="password-input"
            />

            <neb-input
              v-model="formData.confirmPassword"
              :label="$t('auth.signup.confirmPassword.label')"
              type="password"
              :placeholder="$t('auth.signup.confirmPassword.placeholder')"
              required
            />
          </div>
        </neb-validator>

        <div class="form-actions">
          <neb-button
            type="primary"
            :disabled="!isFormValid || formData.password !== formData.confirmPassword"
            class="submit-button"
            @click="handleSubmit()"
          >
            {{ $t('auth.signup.submit') }}
          </neb-button>

          <div class="auth-link">
            <span>{{ $t('auth.signup.hasAccount') }}</span>
            <neb-button type="link" @click="goToLogin()">
              {{ $t('auth.signup.signInLink') }}
            </neb-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.auth-page {
  min-height: 100vh;
  background: var(--neutral-color-25);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-6);
}

.auth-card {
  width: 100%;
  max-width: 400px;
  background: #fff;
  border-radius: var(--radius-large);
  border: 1px solid var(--neutral-color-100);
  box-shadow: var(--shadow-sm);
  padding: var(--space-6);
  view-transition-name: auth-card;

  .neb-content-header {
    view-transition-name: auth-header;
  }

  .email-input {
    view-transition-name: email-input;
  }
  .password-input {
    view-transition-name: password-input;
  }
}

.auth-form {
  margin-top: var(--space-6);
}

.form-fields {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  margin-bottom: var(--space-6);
}

.form-actions {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  view-transition-name: form-actions;
}

.submit-button {
  width: 100%;
}

.auth-link {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--neutral-color-600);
}

@media (--mobile-lg-viewport) {
  .auth-page {
    padding: var(--space-3);
  }

  .auth-card {
    padding: var(--space-4);
  }
}

.dark-mode {
  .auth-card {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);
  }

  .auth-link {
    color: var(--neutral-color-400);
  }
}
</style>
