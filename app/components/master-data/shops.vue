<script setup lang="ts">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { OutShop } from '~/db'

const getQuery = surql`SELECT *, categories.* FROM shop WHERE household = type::thing(${householdGap}) ORDER BY name ASC FETCH categories`

const columns: Columns<OutShop> = {
  name: { text: 'Name' },
}
</script>

<template>
  <master-data-layout
    table="shop"
    name="shop"
    icon="material-symbols:store-outline"
    :get-query
    :columns="columns"
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
