<script setup lang="ts">
import type { InShoppingList, OutShop, OutShoppingList } from '~/db'

const props = defineProps<{
  initialData?: InShoppingList | null
}>()

const emit = defineEmits<{
  change: []
}>()

const modelValue = defineModel<boolean>({ required: true })

const { data: shops } = useAsyncData('shops', async () => {
  const [result] = await db.query<[OutShop[]]>(surql`SELECT * FROM shop ORDER BY name ASC`)
  return result || []
})

const formData = ref<Partial<InShoppingList>>(props.initialData || {
  name: '',
})

const isLoading = ref(false)
const isValid = ref(false)

const title = computed(() => formData.value.id ? 'Edit Shopping List' : 'Create Shopping List')
const actionLabel = computed(() => formData.value.id ? 'Save Changes' : 'Create List')

async function handleSubmit() {
  isLoading.value = true

  try {
    if (formData.value.id) {
      await db.query<[OutShoppingList]>(surql`UPDATE ONLY ${formData.value.id} MERGE ${{
        ...formData.value,
        household: currentHousehold.value!.id,
      }}`)
      useNebToast({ type: 'success', title: 'List updated', description: `"${formData.value.name}" has been updated.` })
    }
    else {
      await db.query<[OutShoppingList]>(
        surql`CREATE shopping_list CONTENT ${{
          ...formData.value,
          items: [],
          household: currentHousehold.value!.id,
        }}`,
      )

      useNebToast({ type: 'success', title: 'List created', description: `"${formData.value.name}" has been created.` })
    }

    emit('change')
  }
  catch (error) {
    console.error('Error saving list:', error)
    useNebToast({ type: 'error', title: formData.value.id ? 'Update failed' : 'Creation failed', description: `Could not ${formData.value.id ? 'update' : 'create'} the shopping list.` })
  }
  finally {
    isLoading.value = false
  }
}
</script>

<template>
  <neb-modal
    v-model="modelValue"
    :title="title"
    :header-icon="formData.id ? 'material-symbols:edit-outline' : 'material-symbols:add-rounded'"
    max-width="500px"
    :close-on-background-click="false"
  >
    <template #content>
      <neb-validator v-model="isValid">
        <neb-input
          v-model="formData.name"
          label="List Name"
          placeholder="e.g., Weekly Groceries, Party Shopping"
          required
          @keydown.enter="handleSubmit()"
        />

        <neb-select
          v-model="formData.shop"
          label="Shop"
          :options="shops!"
          label-key="name"
          track-by-key="id"
          :transform-fun="transformId"
          use-only-tracked-key
          placeholder="Select a shop"
          allow-empty
          no-search
          @keydown.enter="handleSubmit()"
        />
      </neb-validator>
    </template>

    <template #actions>
      <neb-button type="secondary" @click="modelValue = false">
        Cancel
      </neb-button>

      <neb-button
        type="primary"
        :disabled="isLoading || !isValid"
        :loading="isLoading"
        @click="handleSubmit()"
      >
        {{ actionLabel }}
      </neb-button>
    </template>
  </neb-modal>
</template>
