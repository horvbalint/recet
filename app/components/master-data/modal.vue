<script setup lang="ts" generic="T extends Record<string, any>">
const { t } = useI18n()
const props = withDefaults(defineProps<{
  table: string
  name: string
  icon: string
  maxWidth?: string
  initialData?: Partial<T> | null
  transformBeforeCreate?: (data: T) => any
  transformBeforeEdit?: (data: T) => any
}>(), {
  maxWidth: '500px',
  mode: 'create',
  transformBeforeCreate: (data: T) => data,
  transformBeforeEdit: (data: T) => data,
})

const emit = defineEmits<{
  saved: [item: any]
}>()

const modelValue = defineModel<boolean>({ required: true })

const formData = ref<Partial<T>>({})
const isFormValid = ref(false)

const isEdit = computed(() => !!props.initialData?.id)

const title = computed(() => {
  return !isEdit.value ? t('masterData.modal.createTitle', { name: props.name }) : t('masterData.modal.editTitle', { name: props.name })
})

const actionLabel = computed(() => {
  return !isEdit.value ? t('common.create') : t('common.save')
})

watch(() => props.initialData, (newData) => {
  if (newData)
    formData.value = { ...newData }
  else
    formData.value = {}
}, { immediate: true })

watch(modelValue, (isOpen) => {
  if (!isOpen)
    formData.value = {}
})

async function handleSubmit() {
  try {
    if (!isEdit.value) {
      const [result] = await db
        .query(surql`CREATE ONLY type::table(${props.table}) CONTENT ${{
          ...props.transformBeforeCreate(formData.value),
          household: currentHousehold.value!.id,
        }}`)
        .collect<[T]>()

      useNebToast({ type: 'success', title: t('masterData.createSuccess.title', { name: props.name }), description: t('masterData.createSuccess.description', { name: props.name }) })

      emit('saved', result)
    }
    else {
      const [result] = await db
        .query(surql`UPDATE ONLY ${formData.value.id} MERGE ${{
          ...props.transformBeforeEdit(formData.value),
          searchScore: undefined,
          household: currentHousehold.value!.id,
        }} RETURN AFTER`)
        .collect<[T]>()

      useNebToast({ type: 'success', title: t('masterData.updateSuccess.title', { name: props.name }), description: t('masterData.updateSuccess.description', { name: props.name }) })

      emit('saved', result)
    }

    modelValue.value = false
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: t('masterData.saveError.title'), description: t('masterData.saveError.description', { action: !isEdit.value ? 'create' : 'update', name: props.name }) })
  }
}

function handleCancel() {
  modelValue.value = false
}
</script>

<template>
  <neb-modal
    v-model="modelValue"
    :title="title"
    :header-icon="icon"
    :max-width
    :close-on-background-click="false"
  >
    <template #content>
      <neb-validator v-model="isFormValid">
        <div class="modal-form-content">
          <slot name="form" :data="formData" :is-form-valid />
        </div>
      </neb-validator>
    </template>

    <template #actions>
      <neb-button type="tertiary-neutral" @click="handleCancel()">
        {{ $t('common.cancel') }}
      </neb-button>

      <neb-button type="primary" :disabled="!isFormValid" @click="handleSubmit()">
        {{ actionLabel }}
      </neb-button>
    </template>
  </neb-modal>
</template>

<style scoped>
.modal-form-content {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}
</style>
