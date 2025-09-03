<script setup lang="ts">
import type { InUnit, OutUnit } from '~/db'

defineProps<{
  initialData?: Partial<InUnit> | null
}>()

const modelValue = defineModel<boolean>({ required: true })

const emit = defineEmits<{
  'saved': [item: OutUnit]
}>()

function handleSave(item: OutUnit) {
  emit('saved', item)
}
</script>

<template>
  <master-data-modal
    v-model="modelValue"
    table="unit"
    name="unit"
    icon="material-symbols:straighten-outline"
    :initial-data
    @saved="handleSave"
  >
    <template #form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
    </template>
  </master-data-modal>
</template>
