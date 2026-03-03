<script setup lang="ts">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { OutShop } from '~/db'

const { t } = useI18n()
const getQuery = computed(() => surql`SELECT *, categories.* FROM shop WHERE household = ${currentHousehold.value!.id} ORDER BY name ASC FETCH categories`)

const columns = computed(() => ({
  name: { text: t('masterData.shop.columns.name') },
}) satisfies Columns<OutShop>)
</script>

<template>
  <master-data-layout
    table="shop"
    :name="$t('masterData.shop.name')"
    icon="material-symbols:store-outline"
    :get-query
    :columns
  >
    <template #modal="{ close, afterSave, docToEdit }">
      <shop-master-data-modal
        :model-value="true"
        :initial-data="docToEdit"
        @update:model-value="close()"
        @saved="afterSave()"
      />
    </template>
  </master-data-layout>
</template>
