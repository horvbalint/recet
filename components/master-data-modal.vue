<script setup lang="ts" generic="T extends Record<string, any>">
const props = withDefaults(defineProps<{
  modelValue: boolean
  table: string
  name: string
  icon: string
  mode?: 'create' | 'edit'
  initialData?: Partial<T>
  transformBeforeCreate?: (data: T) => any
  transformBeforeEdit?: (data: T) => any
}>(), {
  mode: 'create',
  transformBeforeCreate: (data: T) => data, 
  transformBeforeEdit: (data: T) => data,
})

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  'success': [item: any]
}>()

const formData = ref<any>({})
const isFormValid = ref(false)

const isVisible = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const title = computed(() => {
  return props.mode === 'create' ? `Create new ${props.name}` : `Edit ${props.name}`
})

const actionLabel = computed(() => {
  return props.mode === 'create' ? 'Create' : 'Save Changes'
})

watch(() => props.initialData, (newData) => {
  if (newData) {
    formData.value = { ...newData }
  } else {
    formData.value = {}
  }
}, { immediate: true })

watch(() => props.modelValue, (isOpen) => {
  if (!isOpen) {
    formData.value = {}
  }
})

async function handleSubmit() {
  try {
    if (props.mode === 'create') {
      const [result] = await db.query<[T]>(`INSERT INTO ${props.table} $data RETURN *`, {
        data: props.transformBeforeCreate(formData.value)
      })
      
      useNebToast({
        type: 'success', 
        title: `${props.name} created!`, 
        description: `The ${props.name.toLowerCase()} was saved successfully.`
      })
      
      emit('success', result)
    } else {
      const [result] = await db.query<[T]>(surql`UPDATE ${formData.value.id} MERGE ${props.transformBeforeEdit(formData.value)} RETURN *`)
      
      useNebToast({
        type: 'success', 
        title: `${props.name} updated!`, 
        description: `The ${props.name.toLowerCase()} was updated successfully.`
      })
      
      emit('success', result)
    }
    
    isVisible.value = false
  } catch (error) {
    console.error(error)
    useNebToast({
      type: 'error', 
      title: `${props.mode === 'create' ? 'Creation' : 'Update'} failed!`, 
      description: `Could not ${props.mode === 'create' ? 'create' : 'update'} the ${props.name.toLowerCase()}. Please try again.`
    })
  }
}

function handleCancel() {
  isVisible.value = false
}
</script>

<template>
  <neb-modal 
    v-model="isVisible"
    :title="title"
    :header-icon="icon"
    max-width="500px"
    :close-on-background-click="false"
  >
    <template #content>
      <neb-validator v-model="isFormValid">
        <div class="modal-form-content">
          <slot name="form" :data="formData" />
        </div>
      </neb-validator>
    </template>
    
    <template #actions>
      <neb-button type="tertiary-neutral" @click="handleCancel">
        Cancel
      </neb-button>

      <neb-button type="primary" @click="handleSubmit" :disabled="!isFormValid">
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
