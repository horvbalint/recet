<script setup lang="ts">
import type { OutShoppingList } from '~/db'
import dayjs from 'dayjs'
import relativeTime from 'dayjs/plugin/relativeTime'

const props = defineProps<{
  list: OutShoppingList
}>()

const emit = defineEmits<{
  view: []
  changed: []
}>()

dayjs.extend(relativeTime)

const showRenameModal = ref(false)
const newListName = ref('')
const isRenaming = ref(false)

const menuItems = [
  {
    text: 'Rename',
    icon: 'material-symbols:edit-outline-rounded',
    callback: () => startRename(),
  },
  {
    text: 'Delete',
    icon: 'material-symbols:delete-outline-rounded',
    desctructive: true,
    callback: () => deleteList(),
  },
]

function startRename() {
  newListName.value = props.list.name
  showRenameModal.value = true
}

function handleRenameCancel() {
  showRenameModal.value = false
  newListName.value = ''
}

async function renameList() {
  try {
    isRenaming.value = true
    await db.query(surql`UPDATE ONLY ${props.list.id} SET name = ${newListName.value}`)
    useNebToast({ type: 'success', title: 'List renamed', description: `List has been renamed to "${newListName.value}".` })
    emit('changed')
  }
  catch (error) {
    console.error('Error renaming list:', error)
    useNebToast({ type: 'error', title: 'Rename failed', description: 'Could not rename the shopping list.' })
  }
  finally {
    isRenaming.value = false
  }
}

async function deleteList() {
  try {
    if (!await useNebConfirm({ title: 'Confirm deletion!', description: 'Are you sure you want to delete this shopping list? This action cannot be undone.' }))
      return

    await db.query(surql`DELETE ${props.list.id}`)
    useNebToast({ type: 'success', title: 'List deleted', description: 'Shopping list has been deleted.' })
    emit('changed')
  }
  catch (error) {
    console.error('Error deleting list:', error)
    useNebToast({ type: 'error', title: 'Delete failed', description: 'Could not delete the shopping list.' })
  }
}
</script>

<template>
  <div class="list-card" @click="emit('view')">
    <div class="list-header">
      <div class="list-header-texts">
        <h3 class="list-name">
          {{ props.list.name }}
        </h3>

        <div class="list-stats">
          <neb-badge small>
            {{ props.list.items.length }} items
          </neb-badge>

          <span class="updated-time">{{ dayjs(props.list.updated_at).fromNow() }}</span>
        </div>
      </div>

      <neb-menu :menus="menuItems" :floating-options="{ placement: 'bottom-end' }" @click.stop>
        <template #trigger="{ toggle }">
          <neb-button
            type="tertiary-neutral"
            small
            @click="toggle()"
          >
            <icon name="material-symbols:more-vert" />
          </neb-button>
        </template>
      </neb-menu>
    </div>

    <div class="list-actions">
      <neb-button type="secondary" size="small">
        View List
      </neb-button>
    </div>
  </div>

  <neb-modal v-model="showRenameModal" title="Rename Shopping List">
    <template #content>
      <neb-input
        v-model="newListName"
        label="List Name"
        required
      />
    </template>

    <template #actions>
      <neb-button type="secondary" @click="handleRenameCancel()">
        Cancel
      </neb-button>

      <neb-button type="primary" :loading="isRenaming" :disabled="isRenaming" @click="renameList()">
        Save
      </neb-button>
    </template>
  </neb-modal>
</template>

<style scoped>
.list-card {
  background: #fff;
  border-radius: var(--radius-large);
  border: 1px solid var(--neutral-color-200);
  box-shadow: var(--shadow-sm);
  padding: var(--space-5);
  cursor: pointer;
  transition: all var(--duration-default);
  display: flex;
  flex-direction: column;
  gap: var(--space-8);
}

.list-card:hover {
  box-shadow: var(--shadow-md);
  border-color: var(--primary-color-200);
}

.list-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: var(--space-4);
}

.list-header-texts {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.list-name {
  font-size: var(--text-lg);
  font-weight: var(--font-semibold);
  color: var(--neutral-color-900);
  margin: 0;
}

.list-stats {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.updated-time {
  font-size: var(--text-sm);
  color: var(--neutral-color-500);
}

.list-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}

@media (--tablet-viewport) {
  .list-card {
    padding: var(--space-4);
  }
}

/* Dark mode support */
.dark-mode {
  .list-card {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);
  }

  .list-card:hover {
    border-color: var(--primary-color-600);
  }

  .list-name {
    color: var(--neutral-color-100);
  }

  .updated-time {
    color: var(--neutral-color-400);
  }
}
</style>
