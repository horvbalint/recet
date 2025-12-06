<script setup lang="ts">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { OutUnit } from '~/db'

const getQuery = computed(() => surql`SELECT * FROM unit WITH NOINDEX WHERE household = ${currentHousehold.value!.id} ORDER BY name ASC`)

const columns = {
  name: { text: 'Name' },
} satisfies Columns<OutUnit>
</script>

<template>
  <master-data-layout
    table="unit"
    name="unit"
    icon="material-symbols:straighten-outline"
    :get-query
    :columns
  >
    <template #modal="{ close, afterSave, docToEdit }">
      <unit-master-data-modal
        :model-value="true"
        :initial-data="docToEdit"
        @update:model-value="close()"
        @saved="afterSave()"
      />
    </template>
  </master-data-layout>
</template>
