<script setup lang="ts">
import type { OutUnit } from '~/db'

const props = defineProps<{
  searchTerm?: string
}>()

const modelValue = defineModel<boolean>({ required: true })

const emit = defineEmits<{
  'created': [item: OutUnit]
}>()

function handleSuccess(item: OutUnit) {
  emit('created', item)
}
</script>

<template>
  <master-data-modal
    v-model="modelValue"
    table="unit"
    name="Unit"
    icon="material-symbols:straighten"
    :initial-data="{ name: searchTerm || '' }"
    @success="handleSuccess"
  >
    <template #form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
    </template>
  </master-data-modal>
</template>
