<script setup lang="ts">
import type { InShop, OutIngredientCategory, OutShop } from '~/db'
import { useDragAndDrop } from '@formkit/drag-and-drop/vue'

const props = defineProps<{
  initialData?: Partial<InShop> | null
}>()

const emit = defineEmits<{
  saved: [item: OutShop]
}>()

const modelValue = defineModel<boolean>({ required: true })

const { data: categories } = await useAsyncData(async () => {
  const [result] = await db
    .query(surql`SELECT id, name FROM ingredient_category ORDER BY name ASC`)
    .collect<[OutIngredientCategory[]]>()
  return result
})

const [parent, dragCategories] = useDragAndDrop(props.initialData?.categories || categories.value!)

function transformBeforeCreate(data: any) {
  return {
    ...data,
    categories: dragCategories.value.map((cat: any) => cat.id) || [],
  }
}

function transformBeforeEdit(data: any) {
  return {
    ...data,
    categories: dragCategories.value.map((cat: any) => cat.id) || [],
  }
}

function handleSave(item: OutShop) {
  emit('saved', item)
}
</script>

<template>
  <master-data-modal
    v-model="modelValue"
    table="shop"
    name="shop"
    icon="material-symbols:store-outline"
    :initial-data="initialData || { categories }"
    :transform-before-create
    :transform-before-edit
    @saved="handleSave"
  >
    <template #form="{ data }">
      <neb-input v-model="data.name" label="Name" required />

      <neb-content-header
        title="Categories & order"
        description="Set the order of categories so that they appear in this order in the shopping list."
        type="paragraph"
      />

      <div ref="parent" class="categories-container">
        <div
          v-for="category in dragCategories"
          :key="category.id.toString()"
          class="drag-item"
        >
          <icon name="material-symbols:drag-indicator" />

          <div class="category-content">
            <span class="category-name">{{ category.name }}</span>
          </div>
        </div>
      </div>
    </template>
  </master-data-modal>
</template>

<style scoped>
.categories-container {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.drag-item {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-2) var(--space-1);
  border-radius: var(--radius-small);
  transition: background-color var(--duration-default);
  cursor: grab;
}

.drag-item:hover {
  background: var(--neutral-color-50);
}

.drag-item:active {
  cursor: grabbing;
}

.drag-item .icon {
  color: var(--neutral-color-400);
  transition: color var(--duration-default);
  cursor: grab;
  padding: var(--space-1);
}

.drag-item:hover .drag-handle {
  color: var(--neutral-color-600);
}

.category-content {
  flex: 1;
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--neutral-color-800);
}

.category-name {
  font-weight: 500;
}

.dark-mode {
  .drag-item:hover {
    background: var(--neutral-color-800);
  }

  .drag-handle {
    color: var(--neutral-color-500);
  }

  .drag-item:hover .drag-handle {
    color: var(--neutral-color-300);
  }

  .category-name {
    color: var(--neutral-color-400);
  }

  .category-badge {
    color: var(--neutral-color-300);
  }
}
</style>
