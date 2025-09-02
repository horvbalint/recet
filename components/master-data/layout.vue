<script setup lang="ts" generic="T extends Record<string, any> = Record<string, any>">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue';

const props = defineProps<{
  data: any[] | null | undefined
  status: 'idle' | 'pending' | 'success' | 'error'
  refresh: () => Promise<void>
  columns: Columns<T>
  createButtonText: string
  createModalTitle: string
  createModalIcon?: string
  handleCreate: (data: T) => Promise<void>
  handleEdit?: (data: T) => Promise<void>
  handleDelete?: (data: T) => Promise<void>
}>()

const showCreateModal = ref(false)
const showEditModal = ref(false)
const formData = ref<Partial<T>>({})
const isFormValid = ref(false)

async function handleCreateSubmit() {
  try {
    await props.handleCreate(formData.value)
    showCreateModal.value = false
    formData.value = {}
  } catch (error) {
    console.error('Failed to create item:', error)
  }
}

function handleCreateCancel() {
  showCreateModal.value = false
  formData.value = {}
}

function handleEditClick(item: T) {
  formData.value = { ...item }
  showEditModal.value = true
}

async function handleEditSubmit() {
  try {
    await props.handleEdit!(formData.value)
    showEditModal.value = false
    formData.value = {}
  } catch (error) {
    console.error('Failed to edit item:', error)
  }
}

function handleEditCancel() {
  showEditModal.value = false
  formData.value = {}
}

async function handleDeleteClick(item: T) {
  try {
    if (await useNebConfirm({title: 'Are you sure you want to delete this item?', description: 'This action cannot be undone.'})) {
      await props.handleDelete!(item)
    }
  } catch (error) {
    console.error('Failed to delete item:', error)
  }
}
</script>

<template>
  <div class="master-data-layout">
    <neb-table 
      :columns="columns" 
      :rows="data || []" 
      :status="status" 
      :refresh="refresh"
    >
      <template #actions>
        <neb-button @click="showCreateModal = true" small>
          <icon name="material-symbols:add-rounded" />
          {{ createButtonText }}
        </neb-button>
      </template>

      <template #row-actions="{ data }">
        <icon 
          v-if="handleEdit"
          name="material-symbols:edit-outline-rounded" 
          class="action-icon" 
          @click="handleEditClick(data.original)"
        />
        <icon 
          v-if="handleDelete"
          name="material-symbols:delete-outline-rounded" 
          class="action-icon delete-icon" 
          @click="handleDeleteClick(data.original)"
        />
      </template>

      <template v-for="slot in Object.keys($slots).filter(name => name.startsWith('td-'))" :key="slot" #[slot]="slotProps">
        <slot :name="slot" v-bind="slotProps" />
      </template>
    </neb-table>

    <neb-modal 
      v-model="showCreateModal"
      :title="createModalTitle"
      :header-icon="createModalIcon"
      max-width="500px"
      :close-on-background-click="false"
    >
      <template #content>
        <neb-validator v-model="isFormValid">
          <div class="modal-form-content">
            <slot name="modal-form" :data="formData" />
          </div>
        </neb-validator>
      </template>
      
      <template #actions>
        <neb-button type="tertiary-neutral" @click="handleCreateCancel">
          Cancel
        </neb-button>

        <neb-button type="primary" @click="handleCreateSubmit" :disabled="!isFormValid">
          Create
        </neb-button>
      </template>
    </neb-modal>

    <neb-modal 
      v-model="showEditModal"
      title="Edit Item"
      :header-icon="createModalIcon"
      max-width="500px"
      :close-on-background-click="false"
    >
      <template #content>
        <neb-validator v-model="isFormValid">
          <div class="modal-form-content">
            <slot name="modal-form" :data="formData" />
          </div>
        </neb-validator>
      </template>
      
      <template #actions>
        <neb-button type="tertiary-neutral" @click="handleEditCancel">
          Cancel
        </neb-button>

        <neb-button type="primary" @click="handleEditSubmit" :disabled="!isFormValid">
          Save Changes
        </neb-button>
      </template>
    </neb-modal>
  </div>
</template>

<style scoped>
.master-data-layout {
  width: 100%;
}

.action-icon {
  font-size: 20px !important;
  color: var(--neutral-color-600);
  cursor: pointer;
  transition: all var(--duration-default);
}

.action-icon:hover {
  color: var(--neutral-color-900);
}

.delete-icon:hover {
  color: var(--error-color-600);
}

.modal-form-content {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}
</style>
