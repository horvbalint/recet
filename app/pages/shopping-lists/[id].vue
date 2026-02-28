<script setup lang="ts">
import type { LiveSubscription, RecordId, Uuid } from 'surrealdb'
import type { OutIngredient, OutIngredientCategory, OutRecipe, OutShop, OutShoppingList, OutUnit } from '~/db'
import { Table } from 'surrealdb'

const route = useRoute()
const listId = route.params.id as string

interface ShoppingListItem {
  id: RecordId<'shopping_list_item'>
  item: string | {
    id: RecordId<'ingredient'>
    name: string
    category?: Pick<OutIngredientCategory, 'id' | 'name'>
  }
  amount?: number
  unit?: Pick<OutUnit, 'id' | 'name'>
  recipe?: OutRecipe
  category?: Pick<OutIngredientCategory, 'id' | 'name'>
  marked?: boolean
}

const { status, data, refresh, error } = useAsyncData('shopping-list', async () => {
  const [shoppingList, items, ingredients, units, categories, shops] = await db
    .query(surql`
      SELECT
        *,
        shop.{
          id,
          name,
          categories.{id, name}
        }
      FROM ONLY type::record(shopping_list, ${listId});
      SELECT 
        id,
        item.{
          id,
          name,
          category.{id, name}
        } || item as item,
        amount,
        unit.{id, name},
        recipe.{id, name},
        category.{id, name},
        marked
      FROM shopping_list_item WHERE shopping_list = type::record('shopping_list', ${listId});
      SELECT * FROM ingredient FETCH category;
      SELECT * FROM unit WITH NOINDEX ORDER BY name ASC;
      SELECT * FROM ingredient_category ORDER BY name ASC;
      SELECT * FROM shop ORDER BY name ASC FETCH categories;
    `)
    .collect<[OutShoppingList, ShoppingListItem[], OutIngredient[], OutUnit[], OutIngredientCategory[], OutShop[]]>()
  return { shoppingList, items, ingredients, units, categories, shops }
})

async function setUpLiveQuery() {
  let liveQuery: LiveSubscription | null = null

  onBeforeUnmount(() => {
    if (liveQuery)
      liveQuery.kill()
  })

  try {
    const [liveSelectToken] = await db.query<[Uuid]>(surql`LIVE SELECT VALUE id FROM shopping_list_item WHERE shopping_list = type::record('shopping_list', ${listId})`)
    liveQuery = await db.liveOf(liveSelectToken)
    liveQuery.subscribe(() => refresh())
  }
  catch (err) {
    console.error(err)
    useNebToast({ type: 'warning', title: 'Live update not available!', description: 'Could not set up live updates for this shopping list.' })
  }
}
setUpLiveQuery()

const isLoading = ref(false)
const itemModal = ref<Optional<ShoppingListItem, 'id'> | null>(null)

watch(() => itemModal.value?.item, () => {
  if (typeof itemModal.value?.item === 'object')
    itemModal.value.category = itemModal.value.item.category
})

type DynamicCreateTable = 'ingredient' | 'unit'
const dynamicCreateTable = ref<DynamicCreateTable | null>(null)
const dynamicCreateSearchTerm = ref<string>('')

const shop = ref(data.value?.shoppingList.shop)
watchOnce(data, () => shop.value = data.value?.shoppingList.shop)

const groupedItems = computed(() => {
  if (!data.value?.items)
    return {}

  const categoryList = shop.value?.categories || data.value.categories
  const groups: Record<string, ShoppingListItem[]> = Object.fromEntries(categoryList.map(c => [c.name, []]))

  for (const item of data.value.items) {
    const categoryName = item.category?.name || (typeof item.item === 'object' && item.item?.category?.name) || 'Other'

    if (!groups[categoryName])
      groups[categoryName] = []

    groups[categoryName].push(item)
  }

  for (const category in groups) {
    if (groups[category]!.length === 0)
      delete groups[category]
  }

  return groups
})

async function wrapUpdate(logicFun: () => Promise<unknown>) {
  isLoading.value = true

  try {
    await logicFun()
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

function itemToDbItem(item: Optional<ShoppingListItem, 'id'>) {
  return {
    item: typeof item.item === 'object' ? item.item.id : item.item,
    amount: item.amount,
    unit: item.unit?.id,
    category: item.category?.id,
    recipe: item.recipe?.id,
    marked: item.marked,
    shopping_list: data.value!.shoppingList.id,
    household: currentHousehold.value!.id,
  }
}

function startAddItem() {
  itemModal.value = {
    item: '',
    amount: undefined,
    unit: undefined,
    category: undefined,
  }
}

function handleSubmit() {
  wrapUpdate(async () => {
    if (itemModal.value?.id)
      await db.update(itemModal.value.id).merge(itemToDbItem(itemModal.value))
    else
      await db.create(new Table('shopping_list_item')).content(itemToDbItem(itemModal.value!))

    closeModal()
  })
}

let undoToast: NebToast | null = null
async function removeItem(item: ShoppingListItem) {
  await wrapUpdate(() => db.delete(item.id))

  if (undoToast)
    undoToast.destroy()

  undoToast = useNebToast({
    type: 'success',
    title: `Item removed`,
    timeout: 3000,
    actions: [{
      text: 'Undo',
      callback() {
        undoToast?.destroy()
        wrapUpdate(() => db.create(item.id).content(itemToDbItem(item)))
      },
    }],
  })
}

async function toggleMarkedItem(item: ShoppingListItem) {
  await wrapUpdate(() => db.update(item.id).merge({ marked: !item.marked }))
}

function closeModal() {
  itemModal.value = null
}

function getItemAmount(item: ShoppingListItem) {
  const parts = [item.amount!.toString()]

  if (item.unit)
    parts.push(item.unit.name)

  return parts.join(' ')
}

function startEditItem(item: Optional<ShoppingListItem, 'id'>) {
  itemModal.value = item
}

const modalTitle = computed(() => itemModal.value?.id ? 'Edit Item' : 'Add Item')
const modalSubmitText = computed(() => itemModal.value?.id ? 'Save Changes' : 'Add Item')

watch(currentHousehold, () => goToShoppingLists())

function goToShoppingLists() {
  navigateTo('/shopping-lists')
}

function handleCreateIngredient(searchTerm: string) {
  dynamicCreateSearchTerm.value = searchTerm
  dynamicCreateTable.value = 'ingredient'
}

function handleCreateUnit(searchTerm: string) {
  dynamicCreateSearchTerm.value = searchTerm
  dynamicCreateTable.value = 'unit'
}

function onIngredientCreated(ingredient: OutIngredient) {
  itemModal.value!.item = ingredient
  refresh()
}

function onUnitCreated(unit: OutUnit) {
  itemModal.value!.unit = unit
  refresh()
}
</script>

<template>
  <page-layout>
    <template #content-header>
      <neb-content-header
        has-separator
        :title="data?.shoppingList.name || 'Shopping List'"
        :description="`${data?.items.length || 0} items`"
        icon="material-symbols:shopping-cart-outline-rounded"
        :type="pageHeaderType"
      >
        <template #actions>
          <div class="shop-select-wrapper">
            <neb-select
              v-if="data"
              v-model="shop"
              :options="data!.shops"
              track-by-key="id"
              label-key="name"
              :transform-fun="transformId"
              placeholder="Shop"
              no-search
              allow-empty
            />
          </div>

          <neb-button type="primary" small @click="startAddItem()">
            <icon name="material-symbols:add-rounded" />
            Add Item
          </neb-button>
        </template>
      </neb-content-header>
    </template>

    <div class="page-wrapper">
      <neb-loading-state v-if="status === 'pending'" class="loading-state" />

      <neb-error-state v-if="error" :description="error.message" class="error-state" />

      <div v-else-if="!!data" class="shopping-list-detail">
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
                v-for="item in items"
                :key="`${categoryName}-${typeof item.item === 'object' ? item.item.id : item.item}`"
                class="item-card"
                @click="startEditItem(item)"
              >
                <neb-checkbox class="item-checkbox" @click.stop @update:model-value="removeItem(item)" />

                <div class="item-content">
                  <div class="item-main">
                    <span class="item-name">{{ typeof item.item === 'object' ? item.item.name : item.item }}</span>

                    <neb-badge v-if="item.amount" class="item-amount">
                      {{ getItemAmount(item) }}
                    </neb-badge>
                  </div>

                  <nuxt-link v-if="item.recipe" class="item-recipe" :to="`/recipe/${item.recipe.id.id}`" @click.stop>
                    <icon name="material-symbols:link-rounded" />
                    From {{ item.recipe.name }}
                  </nuxt-link>
                </div>

                <div class="star-wrapper" @click.stop="toggleMarkedItem(item)">
                  <icon v-if="item.marked" class="active" name="material-symbols:star-rounded" />
                  <icon v-else name="material-symbols:star-outline-rounded" />
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
          <neb-button type="primary" @click="startAddItem()">
            Add First Item
          </neb-button>
        </neb-empty-state>
      </div>
    </div>

    <neb-modal
      v-model="itemModal"
      :closed-value="null"
      :title="modalTitle"
      header-icon="material-symbols:add-rounded"
      max-width="600px"
      :close-on-background-click="false"
    >
      <template #content>
        <div class="modal-form-content">
          <suggestion-input
            v-model="itemModal!.item"
            label="Item"
            placeholder="Search an ingredient or add a custom item"
            :options="data!.ingredients"
            label-key="name"
            required
            icon="material-symbols:grocery"
            @new="handleCreateIngredient($event)"
          />

          <div class="amount-row">
            <neb-input
              v-model="itemModal!.amount"
              label="Quantity"
              type="number"
              placeholder="e.g., 2"
              step="0.1"
            />

            <neb-select
              v-model="itemModal!.unit"
              :options="data!.units"
              label="Unit"
              placeholder="Select unit"
              track-by-key="id"
              label-key="name"
              :transform-fun="transformId"
              allow-empty
              no-search
              @new="handleCreateUnit($event)"
            />
          </div>

          <neb-select
            v-model="itemModal!.category"
            :options="data!.categories"
            label="Category"
            placeholder="Select a category"
            track-by-key="id"
            label-key="name"
            :transform-fun="transformId"
            allow-empty
            no-search
          />
        </div>
      </template>

      <template #actions>
        <neb-button type="secondary" @click="closeModal()">
          Cancel
        </neb-button>

        <neb-button
          type="primary"
          :disabled="!itemModal!.item || isLoading"
          :loading="isLoading"
          @click="handleSubmit()"
        >
          {{ modalSubmitText }}
        </neb-button>
      </template>
    </neb-modal>

    <!-- Create modals -->
    <ingredient-master-data-modal
      v-if="dynamicCreateTable === 'ingredient'"
      :model-value="true"
      :initial-data="{ name: dynamicCreateSearchTerm }"
      @update:model-value="dynamicCreateTable = null"
      @saved="onIngredientCreated"
    />

    <unit-master-data-modal
      v-if="dynamicCreateTable === 'unit'"
      :model-value="true"
      :initial-data="{ name: dynamicCreateSearchTerm }"
      @update:model-value="dynamicCreateTable = null"
      @saved="onUnitCreated"
    />
  </page-layout>
</template>

<style scoped>
.page-wrapper {
  position: relative;
}

.shop-select-wrapper {
  width: 110px;
}

.loading-state {
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

.item-amount {
  text-wrap: nowrap;
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
  font-size: var(--text-md);
  color: var(--neutral-color-900);
}

.item-recipe {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-xs);
  color: var(--primary-color-600);
  text-decoration: none;
  width: fit-content;

  &:hover {
    text-decoration: underline;
  }

  .icon {
    font-size: 16px !important;
  }
}

.star-wrapper {
  display: flex;
  align-items: center;
  color: var(--neutral-color-400);
  cursor: pointer;

  .active {
    color: var(--warning-color-500);
  }
}

.modal-form-content {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.amount-row {
  display: flex;
  gap: var(--space-3);
}

@media (--tablet-viewport) {
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

  .loading-state {
    background: rgba(var(--neutral-color-component-950), 0.5);
  }
}
</style>
