<script setup lang="ts">
const router = useRouter()

const formData = ref({
  email: '',
  password: '',
})

const isFormValid = ref(false)

async function handleSubmit() {
  try {
    await signIn(formData.value.email, formData.value.password)

    router.push('/')
  }
  catch (err) {
    console.error(err)

    useNebToast({
      type: 'error',
      title: 'Login failed',
      description: 'Invalid email or password.',
    })
  }
}

function handleSignupClick() {
  router.push('/auth/signup')
}
</script>

<template>
  <div class="auth-page">
    <div class="auth-container">
      <div class="auth-card">
        <neb-content-header
          title="Welcome Back"
          description="Sign in to your account to continue"
          type="section"
        />

        <div class="auth-form">
          <neb-validator v-model="isFormValid">
            <div class="form-fields">
              <neb-input
                v-model="formData.email"
                label="Email"
                type="email"
                placeholder="Enter your email"
                required
              />

              <neb-input
                v-model="formData.password"
                label="Password"
                type="password"
                placeholder="Enter your password"
                required
              />
            </div>
          </neb-validator>

          <div class="form-actions">
            <neb-button
              type="primary"
              :disabled="!isFormValid"
              class="submit-button"
              @click="handleSubmit"
            >
              Sign In
            </neb-button>

            <div class="auth-link">
              <span>Don't have an account?</span>
              <neb-button type="link" @click="handleSignupClick">
                Sign up here
              </neb-button>
            </div>
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

.auth-container {
  width: 100%;
  max-width: 400px;
}

.auth-card {
  background: #fff;
  border-radius: var(--radius-large);
  border: 1px solid var(--neutral-color-100);
  box-shadow: var(--shadow-sm);
  padding: var(--space-6);
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
