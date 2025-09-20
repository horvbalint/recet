<script setup lang="ts">
import type { OutIngredient, OutShoppingList, OutUnit } from '~/db'

const route = useRoute()
const listId = route.params.id as string

const { status, data, refresh, error } = useAsyncData('shopping-list', async () => {
  const [shoppingList, ingredients, units] = await db.query<[OutShoppingList, OutIngredient[], OutUnit[]]>(surql`
    SELECT * FROM ONLY type::thing(shopping_list, ${listId}) FETCH items.ingredient, items.unit, items.recipe, items.ingredient.category;
    SELECT * FROM ingredient;
    SELECT * FROM unit;
  `)
  return { shoppingList, ingredients, units }
})

const isLoading = ref(false)
const showAddItemModal = ref(false)
const newItem = ref({
  ingredient: null as OutIngredient | null,
  amount: '',
  unit: null as OutUnit | null,
  note: '',
})

const groupedItems = computed(() => {
  if (!data.value?.shoppingList.items)
    return {}

  const groups: Record<string, OutShoppingList['items'][number][]> = {}

  for (const item of data.value.shoppingList.items) {
    const categoryName = item.ingredient.category?.name || 'Other'

    if (!groups[categoryName])
      groups[categoryName] = []

    groups[categoryName].push(item)
  }

  return groups
})

const completionProgress = computed(() => {
  if (!data.value?.shoppingList.items.length)
    return 0

  const checkedItems = data.value.shoppingList.items.filter(item => item.checked).length
  return Math.round((checkedItems / data.value.shoppingList.items.length) * 100)
})

async function updateListItems(onSuccess?: () => void) {
  isLoading.value = true

  try {
    const items = data.value!.shoppingList.items.map(item => ({
      ingredient: item.ingredient.id,
      amount: item.amount,
      unit: item.unit?.id,
      checked: item.checked,
      recipe: item.recipe?.id,
    }))

    await db.query(surql`UPDATE ${data.value!.shoppingList.id} SET items = ${items}`)

    if (onSuccess)
      onSuccess()

    await refresh()
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Update failed', description: 'Could not save the changes to the database' })
  }
  finally {
    isLoading.value = false
  }
}

function handleAddItem() {
  data.value!.shoppingList.items.push({
    ingredient: newItem.value.ingredient,
    amount: newItem.value.amount ? Number(newItem.value.amount) : undefined,
    unit: newItem.value.unit,
    checked: false,
  })

  updateListItems(closeModal)
}

async function removeItem(item: OutShoppingList['items'][number]) {
  const confirmed = await useNebConfirm({
    title: 'Are you sure you want to remove this item?',
    description: 'This action cannot be undone.',
  })
  if (!confirmed)
    return

  data.value!.shoppingList.items = data.value!.shoppingList.items.filter(i => i !== item)
  updateListItems()
}

function closeModal() {
  showAddItemModal.value = false
  newItem.value = {
    ingredient: null,
    amount: '',
    unit: null,
    note: '',
  }
}

function getItemAmount(item: OutShoppingList['items'][number]) {
  const parts = [item.amount!.toString()]

  if (item.unit)
    parts.push(item.unit.name)

  return parts.join(' ')
}

function goBack() {
  navigateTo('/shopping-lists')
}
</script>

<template>
  <nuxt-layout name="app">
    <template #content-header>
      <neb-content-header
        has-separator
        :title="data?.shoppingList.name || 'Shopping List'"
        :description="`${data?.shoppingList.items.length || 0} items • ${completionProgress}% complete`"
        icon="material-symbols:shopping-cart-outline-rounded"
      >
        <template #actions>
          <neb-button type="secondary" @click="goBack()">
            <icon name="material-symbols:arrow-back-rounded" />
            Back
          </neb-button>

          <neb-button type="primary" @click="showAddItemModal = true">
            <icon name="material-symbols:add-rounded" />
            Add Item
          </neb-button>
        </template>
      </neb-content-header>
    </template>

    <neb-state-content :status :refresh :error-description="error?.message">
      <div class="shopping-list-detail">
        <!-- Progress Bar -->
        <div v-if="Object.keys(groupedItems).length > 0" class="progress-section">
          <div class="progress-header">
            <span class="progress-label">Progress</span>
            <span class="progress-text">{{ completionProgress }}% complete</span>
          </div>
          <div class="progress-bar">
            <div class="progress-fill" :style="{ width: `${completionProgress}%` }" />
          </div>
        </div>

        <!-- Items by Category -->
        <div v-if="Object.keys(groupedItems).length > 0" class="categories-container">
          <div
            v-for="(items, categoryName) in groupedItems"
            :key="categoryName"
            class="category-section"
          >
            <h3 class="category-title">
              {{ categoryName }}
              <span class="category-count">({{ items.length }})</span>
            </h3>

            <div class="items-list">
              <div
                v-for="(item, index) in items"
                :key="index"
                class="item-card"
                :class="{ 'item-checked': item.checked }"
              >
                <div class="item-checkbox">
                  <neb-checkbox v-model="item.checked" @update:model-value="updateListItems()" />
                </div>

                <div class="item-content">
                  <div class="item-main">
                    <span class="item-name">{{ item.ingredient.name || 'Unknown ingredient' }}</span>

                    <neb-badge v-if="item.amount">
                      {{ getItemAmount(item) }}
                    </neb-badge>
                  </div>

                  <div v-if="item.recipe" class="item-recipe">
                    <icon name="material-symbols:restaurant-rounded" />
                    From recipe
                  </div>
                </div>

                <div class="item-actions">
                  <icon name="material-symbols:delete-outline-rounded" @click="removeItem(item)" />
                </div>
              </div>
            </div>
          </div>
        </div>

        <neb-empty-state
          v-else
          icon="material-symbols:shopping-cart-outline-rounded"
          title="No items yet"
          description="Add your first item to start shopping."
        >
          <neb-button type="primary" @click="showAddItemModal = true">
            Add First Item
          </neb-button>
        </neb-empty-state>
      </div>
    </neb-state-content>

    <!-- Add Item Modal -->
    <neb-modal
      v-model="showAddItemModal"
      title="Add Item"
      header-icon="material-symbols:add-rounded"
      max-width="600px"
      :close-on-background-click="false"
    >
      <template #content>
        <div class="modal-form-content">
          <neb-select
            v-model="newItem.ingredient"
            :options="data!.ingredients || []"
            label="Ingredient"
            placeholder="Select an ingredient"
            track-by-key="name"
            label-key="name"
            required
            :disabled="isLoading"
          />

          <div class="amount-row">
            <neb-input
              v-model="newItem.amount"
              label="Quantity"
              type="number"
              placeholder="e.g., 2"
              step="0.1"
              :disabled="isLoading"
              class="amount-input"
            />

            <neb-select
              v-model="newItem.unit"
              :options="data!.units || []"
              label="Unit"
              placeholder="Select unit"
              track-by-key="name"
              label-key="name"
              :disabled="isLoading"
              allow-empty
              class="unit-select"
            />
          </div>
        </div>
      </template>

      <template #actions>
        <neb-button type="secondary" @click="closeModal()">
          Cancel
        </neb-button>

        <neb-button
          type="primary"
          :disabled="!newItem.ingredient || isLoading"
          :loading="isLoading"
          @click="handleAddItem()"
        >
          Add Item
        </neb-button>
      </template>
    </neb-modal>
  </nuxt-layout>
</template>

<style scoped>
.shopping-list-detail {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.progress-section {
  background: #fff;
  border-radius: var(--radius-large);
  border: 1px solid var(--neutral-color-200);
  padding: var(--space-5);
}

.progress-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--space-3);
}

.progress-label {
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  color: var(--neutral-color-700);
}

.progress-text {
  font-size: var(--text-sm);
  color: var(--neutral-color-600);
}

.progress-bar {
  height: 8px;
  background: var(--neutral-color-100);
  border-radius: var(--radius-large);
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: var(--primary-color-500);
  border-radius: var(--radius-large);
  transition: width var(--duration-default);
}

.categories-container {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.category-section {
  background: #fff;
  border-radius: var(--radius-large);
  border: 1px solid var(--neutral-color-200);
  overflow: hidden;
}

.category-title {
  font-size: var(--text-lg);
  font-weight: 500;
  color: var(--neutral-color-900);
  margin: 0;
  padding: var(--space-3) var(--space-4);
  background: var(--neutral-color-50);
  border-bottom: 1px solid var(--neutral-color-200);
}

.category-count {
  color: var(--neutral-color-600);
  font-weight: var(--font-normal);
}

.items-list {
  display: flex;
  flex-direction: column;
}

.item-card {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-2) var(--space-3);
  border-bottom: 1px solid var(--neutral-color-100);
  transition: all var(--duration-default);
}

.item-card:last-child {
  border-bottom: none;
}

.item-card.item-checked {
  opacity: 0.6;
}

.item-card.item-checked .item-name {
  text-decoration: line-through;
}

.item-checkbox {
  margin-top: var(--space-1);
}

.item-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.item-main {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.item-name {
  font-size: var(--text-base);
  font-weight: var(--font-medium);
  color: var(--neutral-color-900);
}

.item-recipe {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-xs);
  color: var(--primary-color-600);
}

.item-actions {
  display: flex;
  align-items: flex-start;
  gap: var(--space-2);
  margin-top: var(--space-1);

  .icon {
    cursor: pointer;
    color: var(--neutral-color-500);
  }
}

.modal-form-content {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.amount-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-3);
}

@media (--tablet-viewport) {
  .amount-row {
    grid-template-columns: 1fr;
  }

  .categories-container {
    gap: var(--space-4);
  }

  .item-card {
    padding: var(--space-3) var(--space-4);
  }
}
</style>
