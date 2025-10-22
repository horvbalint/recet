<script setup lang="ts">
import type { RecordId } from 'surrealdb'
import type { OutShoppingList } from '~/db'

definePageMeta({
  layout: 'app',
})

const router = useRouter()

const { data: shoppingLists, status: shoppingListsStatus, refresh: refreshShoppingLists } = useAsyncData('shopping-lists', async () => {
  const [shoppingLists] = await db
    .query(surql`
      SELECT
        *
      FROM
        shopping_list
      WHERE
        household = ${currentHousehold.value!.id}
      ORDER BY
        updated_at DESC
      FETCH
        shop
    `)
    .collect<[OutShoppingList[]]>()

  return shoppingLists
}, { watch: [currentHousehold] })

const status = shoppingListsStatus
async function refresh() {
  await refreshShoppingLists()
}

const showCreateModal = ref(false)

async function handleListChange() {
  showCreateModal.value = false
  await refresh()
}

function handleViewList(listId: RecordId<'shopping_list'>) {
  router.push(`/shopping-lists/${listId.id}` as any)
}
</script>

<template>
  <page-layout>
    <template #content-header>
      <neb-content-header
        title="Shopping Lists"
        description="Manage your household shopping lists"
        has-separator
        :type="pageHeaderType"
      >
        <template v-if="shoppingLists?.length" #actions>
          <neb-button small type="primary" @click="showCreateModal = true">
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

    <shopping-list-modal
      v-model="showCreateModal"
      @change="handleListChange()"
    />
  </page-layout>
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

@media (--tablet-viewport) {
  .lists-grid {
    grid-template-columns: 1fr;
    gap: var(--space-4);
  }
}
</style>
