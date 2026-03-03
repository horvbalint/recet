<script setup lang="ts">
import type { OutHousehold } from '~/db'

const { t } = useI18n()
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

    useNebToast({ type: 'success', title: t('household.create.success.title'), description: t('household.create.success.description', { name: household.name }) })

    emit('created', household)
    modelValue.value = false
  }
  catch (error) {
    console.error('Error creating household:', error)
    useNebToast({ type: 'error', title: t('household.create.error.title'), description: t('household.create.error.description') })
  }
}

watch(modelValue, (visible) => {
  if (visible)
    householdName.value = ''
})
</script>

<template>
  <neb-modal v-model="modelValue" :title="$t('household.create.title')" header-icon="material-symbols:home-rounded">
    <template #content>
      <neb-validator v-model="isFormValid">
        <neb-input
          v-model="householdName"
          :label="$t('household.create.name.label')"
          :placeholder="$t('household.create.name.placeholder')"
          required
        />
      </neb-validator>
    </template>

    <template #actions>
      <neb-button type="secondary" @click="modelValue = false">
        {{ $t('common.cancel') }}
      </neb-button>

      <neb-button type="primary" :disabled="!isFormValid" @click="handleCreate()">
        {{ $t('household.create.submit') }}
      </neb-button>
    </template>
  </neb-modal>
</template>
