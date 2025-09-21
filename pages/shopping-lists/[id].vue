<script setup lang="ts">
import type { InShoppingList, OutIngredient, OutShoppingList, OutUnit } from '~/db'

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
const showFormModal = ref<'add' | { type: 'edit', categoryName: string, index: number } | null>(null)
const newItem = ref({
  ingredient: null as OutIngredient | null,
  amount: '',
  unit: null as OutUnit | null,
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

function handleSubmit() {
  if (typeof showFormModal.value === 'object') {
    Object.assign(groupedItems.value[showFormModal.value!.categoryName]![showFormModal.value!.index]!, newItem.value)
  }
  else {
    data.value!.shoppingList.items.push({
      ingredient: newItem.value.ingredient,
      amount: newItem.value.amount ? Number(newItem.value.amount) : undefined,
      unit: newItem.value.unit,
      checked: false,
    })
  }

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
  showFormModal.value = null
  newItem.value = {
    ingredient: null,
    amount: '',
    unit: null,
  }
}

function getItemAmount(item: OutShoppingList['items'][number]) {
  const parts = [item.amount!.toString()]

  if (item.unit)
    parts.push(item.unit.name)

  return parts.join(' ')
}

function startEditItem(categoryName: string, index: number) {
  newItem.value = { ...groupedItems.value[categoryName]![index] }
  showFormModal.value = { type: 'edit', categoryName, index }
}

const modalTitle = computed(() => showFormModal.value === 'add' ? 'Add Item' : 'Edit Item')
const modalSubmitText = computed(() => typeof showFormModal.value === 'object' ? 'Save Changes' : 'Add Item')

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
        :description="`${data?.shoppingList.items.length || 0} items`"
        icon="material-symbols:shopping-cart-outline-rounded"
      >
        <template #actions>
          <neb-button type="secondary" @click="goBack()">
            <icon name="material-symbols:arrow-back-rounded" />
            Back
          </neb-button>

          <neb-button type="primary" @click="showFormModal = 'add'">
            <icon name="material-symbols:add-rounded" />
            Add Item
          </neb-button>
        </template>
      </neb-content-header>
    </template>

    <div class="page-wrapper">
      <div v-if="status !== 'success'" class="loading-wrapper">
        <neb-state-content :status :refresh :error-description="error?.message" />
      </div>

      <div v-if="!!data" class="shopping-list-detail">
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
                <neb-checkbox v-model="item.checked" @update:model-value="updateListItems()" />

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
                  <icon name="material-symbols:edit-outline-rounded" @click="startEditItem(categoryName, index)" />
                  <icon name="material-symbols:close-rounded" @click="removeItem(item)" />
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
          <neb-button type="primary" @click="showFormModal = 'add'">
            Add First Item
          </neb-button>
        </neb-empty-state>
      </div>
    </div>

    <neb-modal
      v-model="showFormModal"
      :closed-value="null"
      :title="modalTitle"
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
          @click="handleSubmit()"
        >
          {{ modalSubmitText }}
        </neb-button>
      </template>
    </neb-modal>
  </nuxt-layout>
</template>

<style scoped>
.page-wrapper {
  position: relative;
}

.loading-wrapper {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(var(--neutral-color-component-50), 0.5);
  z-index: 10;
}

.shopping-list-detail {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
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

/* Dark mode support */
.dark-mode {
  .category-section {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);
  }

  .category-title {
    color: var(--neutral-color-100);
    background: var(--neutral-color-800);
    border-color: var(--neutral-color-700);
  }

  .category-count {
    color: var(--neutral-color-400);
  }

  .item-card {
    border-color: var(--neutral-color-800);
  }

  .item-name {
    color: var(--neutral-color-100);
  }

  .item-recipe {
    color: var(--primary-color-400);
  }

  .item-actions .icon {
    color: var(--neutral-color-400);
  }

  .item-actions .icon:hover {
    color: var(--neutral-color-200);
  }
}
</style>
