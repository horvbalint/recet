<script setup lang="ts">
definePageMeta({
  layout: 'empty',
})

const formData = ref({
  username: '',
  email: '',
  password: '',
  confirmPassword: '',
})

const isFormValid = ref(false)

async function handleSubmit() {
  if (formData.value.password !== formData.value.confirmPassword) {
    useNebToast({ type: 'error', title: 'Password mismatch', description: 'Passwords do not match. Please try again.' })
    return
  }

  try {
    await signUp(formData.value.email, formData.value.username, formData.value.password)

    useNebToast({ type: 'success', title: 'Account created!', description: 'Your account has been created successfully. Please sign in.' })

    goToLogin()
  }
  catch (error) {
    console.error('Signup error:', error)

    useNebToast({ type: 'error', title: 'Signup failed', description: 'Could not create account. Email or username may already be in use.' })
  }
}

function goToLogin() {
  navigateToWithTransition('/auth/login')
}
</script>

<template>
  <div class="auth-page">
    <div class="auth-card">
      <neb-content-header
        title="Create Account"
        description="Sign up to start managing your recipes"
        type="section"
      />

      <div class="auth-form">
        <neb-validator v-model="isFormValid">
          <div class="form-fields">
            <neb-input
              v-model="formData.username"
              label="Username"
              placeholder="Enter your username"
              required
            />

            <neb-input
              v-model="formData.email"
              label="Email"
              type="email"
              placeholder="Enter your email"
              required
              class="email-input"
            />

            <neb-input
              v-model="formData.password"
              label="Password"
              type="password"
              placeholder="Enter your password"
              required
              class="password-input"
            />

            <neb-input
              v-model="formData.confirmPassword"
              label="Confirm Password"
              type="password"
              placeholder="Confirm your password"
              required
            />
          </div>
        </neb-validator>

        <div class="form-actions">
          <neb-button
            type="primary"
            :disabled="!isFormValid"
            class="submit-button"
            @click="handleSubmit()"
          >
            Create Account
          </neb-button>

          <div class="auth-link">
            <span>Already have an account?</span>
            <neb-button type="link" @click="goToLogin()">
              Sign in here
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
