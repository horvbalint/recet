<script setup lang="ts" generic="T extends Record<string, any>">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue';
import type { PreparedQuery } from 'surrealdb';

const props = withDefaults(defineProps<{
  table: string,
  columns: Columns<T>
  getQuery: PreparedQuery,
  name: string
  icon: string
  transformBeforeCreate?: (data: T) => any
  transformBeforeEdit?: (data: T) => any
}>(), {
  transformBeforeCreate: (data: T) => data, 
  transformBeforeEdit: (data: T) => data, 
})

const showCreateModal = ref(false)
const showEditModal = ref(false)
const formData = ref<Partial<T>>({})
const isFormValid = ref(false)

const { data, status, refresh } = await useAsyncData('ingredient-categories', async () => {
  const [result] = await db.query<[T[]]>(props.getQuery)
  return result || []
})

async function handleCreateSubmit() {
  try {
    await db.query(`INSERT INTO ${props.table} $data`, {data: props.transformBeforeCreate(formData.value)})
    await refresh()

    useNebToast({type: 'success', title: 'Item created!', description: 'The item was saved into the database.'})
    
    showCreateModal.value = false
    formData.value = {}
  } catch (error) {
    console.error(error)
    useNebToast({type: 'error', title: 'Creation failed!', description: 'We could not save the item into the database.'})
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
    await db.query(surql`UPDATE ${formData.value.id} MERGE ${props.transformBeforeEdit(formData.value)}`)
    await refresh()

    useNebToast({type: 'success', title: 'Modification saved!', description: 'The modifications were saved into the database.'})

    showEditModal.value = false
    formData.value = {}
  } catch (error) {
    console.error(error)
    useNebToast({type: 'error', title: 'Edit failed!', description: 'We could not save the item into the database.'})
  }
}

function handleEditCancel() {
  showEditModal.value = false
  formData.value = {}
}

async function handleDeleteClick(item: T) {
  try {
    if (!await useNebConfirm({title: 'Are you sure you want to delete this item?', description: 'This action cannot be undone.'}))
      return

    await db.query(surql`DELETE ${formData.value.id}`)
    await refresh()

    useNebToast({type: 'success', title: 'Succesfully deleted!', description: 'The item got removed from the database.'})
  } catch (error) {
    console.error(error)
    useNebToast({type: 'error', title: 'Deletion failed!', description: 'We could not remove the item from the database.'})
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
          Add {{ props.name }}
        </neb-button>
      </template>

      <template #row-actions="{ data }">
        <icon 
          name="material-symbols:edit-outline-rounded" 
          class="action-icon" 
          @click="handleEditClick(data.original)"
        />
        <icon 
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
      :title="`Create new ${props.name}`"
      :header-icon="icon"
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
      :title="`Edit ${props.name}`"
      :header-icon="icon"
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
