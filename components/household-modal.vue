<script setup lang="ts">
import type { OutHousehold } from '~/db'

const emit = defineEmits<{
  (event: 'created', household: OutHousehold): void
}>()

const modelValue = defineModel<boolean>()

const householdName = ref('')
const isFormValid = ref(false)

async function handleCreate() {
  if (!householdName.value.trim())
    return

  try {
    const household = await createHousehold(householdName.value.trim())

    useNebToast({
      type: 'success',
      title: 'Household created!',
      description: `${household.name} has been created successfully.`,
    })

    emit('created', household)
    modelValue.value = false
  }
  catch (error) {
    console.error('Error creating household:', error)
    useNebToast({
      type: 'error',
      title: 'Creation failed',
      description: 'Could not create household. Please try again.',
    })
  }
}

watch(modelValue, (visible) => {
  if (visible)
    householdName.value = ''
})
</script>

<template>
  <neb-modal v-model="modelValue" title="Create Household" header-icon="material-symbols:home-rounded">
    <template #content>
      <neb-validator v-model="isFormValid">
        <neb-input
          v-model="householdName"
          label="Household Name"
          placeholder="Enter household name"
          required
        />
      </neb-validator>
    </template>

    <template #actions>
      <neb-button type="secondary" @click="modelValue = false">
        Cancel
      </neb-button>

      <neb-button
        type="primary"
        :disabled="!isFormValid"
        @click="handleCreate"
      >
        Create Household
      </neb-button>
    </template>
  </neb-modal>
</template>
