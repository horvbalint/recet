<script setup lang="ts">
import type { InIngredient, OutIngredient, OutIngredientCategory } from '~/db'

defineProps<{
  initialData?: Partial<InIngredient> | null
}>()

const emit = defineEmits<{
  saved: [item: OutIngredient]
}>()

const modelValue = defineModel<boolean>({ required: true })

const dynamicCreateTable = ref<'ingredient_category' | null>(null)
const dynamicCreateSearchTerm = ref<string>('')

const { data: categories, refresh: refreshCategories } = await useAsyncData(async () => {
  const [result] = await db.query<[OutIngredientCategory[]]>(surql`SELECT id, name FROM ingredient_category ORDER BY name ASC`)
  return result || []
})

function transformBeforeCreate(data: any) {
  return {
    ...data,
    category: data.category?.id,
  }
}

function transformBeforeEdit(data: any) {
  return {
    ...data,
    category: data.category?.id,
  }
}

function handleSave(item: OutIngredient) {
  emit('saved', item)
}

function handleCreateCategory(searchTerm: string) {
  dynamicCreateSearchTerm.value = searchTerm
  dynamicCreateTable.value = 'ingredient_category'
}

function onCategoryCreated() {
  refreshCategories()
}
</script>

<template>
  <master-data-modal
    v-model="modelValue"
    table="ingredient"
    name="ingredient"
    icon="material-symbols:inventory-2-outline-rounded"
    :initial-data
    :transform-before-create
    :transform-before-edit
    @saved="handleSave"
  >
    <template #form="{ data }">
      <neb-input v-model="data.name" label="Name" required />

      <neb-select
        v-model="data.category"
        label="Category"
        :options="categories || []"
        label-key="name"
        track-by-key="name"
        placeholder="Select a category"
        allow-empty
        @new="handleCreateCategory($event)"
      />

      <neb-checkbox v-model="data.skip_from_shopping_list" label="Skip from shopping list" />
    </template>
  </master-data-modal>

  <ingredient-category-master-data-modal
    v-if="dynamicCreateTable === 'ingredient_category'"
    :model-value="true"
    :initial-data="{ name: dynamicCreateSearchTerm }"
    @update:model-value="dynamicCreateTable = null"
    @saved="onCategoryCreated()"
  />
</template>
