<script setup lang="ts">
import type { RecordId } from 'surrealdb'
import type { OutShoppingList } from '~/db'

const router = useRouter()

const { status, data: shoppingLists, refresh } = await useAsyncData('shopping-lists', () => db.select('shopping_list') as Promise<OutShoppingList[]>)

const isLoading = ref(false)
const showCreateModal = ref(false)
const newListName = ref('')

async function handleCreateList() {
  if (!newListName.value.trim()) {
    return
  }

  isLoading.value = true
  try {
    await db.query(surql`CREATE shopping_list CONTENT ${{
      name: newListName.value.trim(),
      items: [],
      household: currentHousehold.value!.id,
    }}`)

    useNebToast({ type: 'success', title: 'List created', description: `"${newListName.value}" has been created.` })

    newListName.value = ''
    showCreateModal.value = false
    await refresh()
  }
  catch (error) {
    console.error('Error creating list:', error)
    useNebToast({ type: 'error', title: 'Creation failed', description: 'Could not create the shopping list.' })
  }
  finally {
    isLoading.value = false
  }
}

function handleCloseModal() {
  showCreateModal.value = false
  newListName.value = ''
}

function handleViewList(listId: RecordId<'shopping_list'>) {
  router.push(`/shopping-lists/${listId.id}` as any)
}
</script>

<template>
  <nuxt-layout name="app">
    <template #content-header>
      <neb-content-header
        title="Shopping Lists"
        description="Manage your household shopping lists"
        has-separator
      >
        <template #actions>
          <neb-button type="primary" @click="showCreateModal = true">
            <icon name="material-symbols:add-rounded" />
            New List
          </neb-button>
        </template>
      </neb-content-header>
    </template>

    <neb-state-content :status :refresh>
      <div class="shopping-lists-page">
        <div v-if="shoppingLists?.length" class="lists-grid">
          <shopping-list-card
            v-for="list in shoppingLists"
            :key="list.id.toString()"
            :list="list"
            @view="handleViewList(list.id)"
            @changed="refresh()"
          />
        </div>

        <neb-empty-state
          v-else
          icon="material-symbols:shopping-cart-outline-rounded"
          title="No shopping lists yet"
          description="Create your first shopping list to get started."
        >
          <neb-button type="primary" @click="showCreateModal = true">
            Create First List
          </neb-button>
        </neb-empty-state>
      </div>
    </neb-state-content>

    <!-- Create List Modal -->
    <neb-modal
      v-model="showCreateModal"
      title="Create Shopping List"
      header-icon="material-symbols:add-rounded"
      max-width="500px"
      :close-on-background-click="false"
    >
      <template #content>
        <div class="modal-form-content">
          <neb-input
            v-model="newListName"
            label="List Name"
            placeholder="e.g., Weekly Groceries, Party Shopping"
            required
            :disabled="isLoading"
            @keydown.enter="handleCreateList()"
          />
        </div>
      </template>

      <template #actions>
        <neb-button type="secondary" @click="handleCloseModal()">
          Cancel
        </neb-button>

        <neb-button
          type="primary"
          :disabled="!newListName.trim() || isLoading"
          :loading="isLoading"
          @click="handleCreateList()"
        >
          Create List
        </neb-button>
      </template>
    </neb-modal>
  </nuxt-layout>
</template>

<style scoped>
.shopping-lists-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.lists-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: var(--space-6);
}

.modal-form-content {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

@media (--tablet-viewport) {
  .lists-grid {
    grid-template-columns: 1fr;
    gap: var(--space-4);
  }
}
</style>
