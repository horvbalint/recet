<script setup lang="ts">
import type { InShoppingList, OutShop, OutShoppingList } from '~/db'

const { t } = useI18n()
const props = defineProps<{
  initialData?: Pick<InShoppingList, 'name' | 'shop'> | null
}>()

const emit = defineEmits<{
  change: []
}>()

const modelValue = defineModel<boolean>({ required: true })

const { data: shops } = useAsyncData('shops', async () => {
  const [result] = await db
    .query(surql`SELECT * FROM shop ORDER BY name ASC`)
    .collect<[OutShop[]]>()
  return result || []
})

const formData = ref<Partial<InShoppingList>>(props.initialData || {
  name: '',
})

const isLoading = ref(false)
const isValid = ref(false)

const title = computed(() => formData.value.id ? t('shoppingLists.modal.title.edit') : t('shoppingLists.modal.title.create'))
const actionLabel = computed(() => formData.value.id ? t('common.save') : t('shoppingLists.modal.createButton'))

async function handleSubmit() {
  isLoading.value = true

  try {
    if (formData.value.id) {
      await db
        .query(surql`UPDATE ONLY ${formData.value.id} MERGE ${{
          ...formData.value,
          household: currentHousehold.value!.id,
        }}`)
        .collect<[OutShoppingList]>()

      useNebToast({ type: 'success', title: t('shoppingLists.modal.updateSuccess.title'), description: t('shoppingLists.modal.updateSuccess.description', { name: formData.value.name }) })
    }
    else {
      await db
        .query(surql`CREATE shopping_list CONTENT ${{
          ...formData.value,
          items: [],
          household: currentHousehold.value!.id,
        }}`)
        .collect<[OutShoppingList]>()

      useNebToast({ type: 'success', title: t('shoppingLists.modal.createSuccess.title'), description: t('shoppingLists.modal.createSuccess.description', { name: formData.value.name }) })
    }

    emit('change')
  }
  catch (error) {
    console.error('Error saving list:', error)
    useNebToast({ type: 'error', title: t('shoppingLists.modal.error.title'), description: t('shoppingLists.modal.error.description') })
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
          :label="$t('shoppingLists.modal.name.label')"
          :placeholder="$t('shoppingLists.modal.name.placeholder')"
          required
          @keydown.enter="handleSubmit()"
        />

        <neb-select
          v-model="formData.shop"
          :label="$t('shoppingLists.modal.shop.label')"
          :options="shops!"
          label-key="name"
          track-by-key="id"
          :transform-fun="transformId"
          use-only-tracked-key
          :placeholder="$t('shoppingLists.modal.shop.placeholder')"
          allow-empty
          no-search
          @keydown.enter="handleSubmit()"
        />
      </neb-validator>
    </template>

    <template #actions>
      <neb-button type="secondary" @click="modelValue = false">
        {{ $t('common.cancel') }}
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
