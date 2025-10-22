<script setup lang="ts" generic="T extends Record<string, any>">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { PreparedQuery } from 'surrealdb'

const props = defineProps<{
  table: string
  columns: Columns<T>
  getQuery: PreparedQuery
  name: string
  icon: string
}>()

const showModal = ref(false)

const { data, status, refresh } = useAsyncData(`${props.table}-master-data-layout`, async () => {
  const [result] = await db
    .query(props.getQuery)
    .collect<[T[]]>()
  return result || []
}, { watch: [currentHousehold] })

function handleCreateClick() {
  showModal.value = true
}

const docToEdit = ref<T | null>(null)
function handleEditClick(item: T) {
  docToEdit.value = item
  showModal.value = true
}

async function handleDeleteClick(item: T) {
  try {
    if (!await useNebConfirm({ title: 'Are you sure you want to delete this item?', description: 'This action cannot be undone.' }))
      return

    await db
      .query(surql`DELETE ${item.id}`)
      .collect()
    await refresh()

    useNebToast({ type: 'success', title: 'Succesfully deleted!', description: 'The item got removed from the database.' })
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Deletion failed!', description: 'We could not remove the item from the database.' })
  }
}

function closeModal() {
  showModal.value = false
  docToEdit.value = null
}
</script>

<template>
  <div class="master-data-layout">
    <neb-table
      :columns
      :rows="data || []"
      :status="status"
      :refresh="refresh"
    >
      <template #actions>
        <neb-button small @click="handleCreateClick()">
          <Icon name="material-symbols:add-rounded" />
          Add {{ props.name }}
        </neb-button>
      </template>

      <template #row-actions="{ data: { original } }">
        <Icon
          name="material-symbols:edit-outline-rounded"
          class="row-action"
          @click="handleEditClick(original)"
        />
        <Icon
          name="material-symbols:delete-outline-rounded"
          class="row-action delete-action"
          @click="handleDeleteClick(original)"
        />
      </template>

      <template v-for="slot in Object.keys($slots).filter(name => name.startsWith('td-'))" :key="slot" #[slot]="slotProps">
        <slot :name="slot" v-bind="slotProps" />
      </template>
    </neb-table>

    <slot v-if="showModal" name="modal" :after-save="refresh" :close="closeModal" :doc-to-edit />
  </div>
</template>

<style scoped>
.master-data-layout {
  width: 100%;
}
</style>
