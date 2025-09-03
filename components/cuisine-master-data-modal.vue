<script setup lang="ts">
import type { InCuisine, OutCuisine } from '~/db'

defineProps<{
  initialData?: Partial<InCuisine> | null
}>()

const modelValue = defineModel<boolean>({required: true})

const emit = defineEmits<{
  'saved': [item: OutCuisine]
}>()

// Flag emoji options
const flagOptions = [
  '🇺🇸', '🇬🇧', '🇫🇷', '🇮🇹', '🇪🇸', '🇩🇪', '🇯🇵', '🇨🇳', '🇮🇳', '🇰🇷',
  '🇹🇭', '🇻🇳', '🇲🇽', '🇧🇷', '🇦🇷', '🇵🇪', '🇨🇦', '🇦🇺', '🇷🇺', '🇺🇦',
  '🇵🇱', '🇨🇿', '🇭🇺', '🇷🇴', '🇬🇷', '🇹🇷', '🇪🇬', '🇲🇦', '🇿🇦', '🇳🇬',
  '🇮🇱', '🇱🇧', '🇸🇦', '🇦🇪', '🇮🇷', '🇵🇰', '🇧🇩', '🇱🇰', '🇳🇵', '🇲🇾',
  '🇸🇬', '🇮🇩', '🇵🇭', '🇰🇭', '🇱🇦', '🇲🇲', '🇪🇹', '🇰🇪', '🇬🇭', '🇨🇮'
]

function handleSave(item: OutCuisine) {
  emit('saved', item)
}
</script>

<template>
  <master-data-modal
    v-model="modelValue"
    table="cuisine"
    name="cuisine"
    icon="material-symbols:public"
    :initial-data
    @saved="handleSave"
  >
    <template #form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
      
      <neb-input v-model="data.color" label="Color" type="color" required />
      
      <neb-select 
        v-model="data.flag" 
        label="Flag" 
        no-search 
        :options="flagOptions" 
        placeholder="Select a flag" 
        allow-empty 
      />
    </template>
  </master-data-modal>
</template>
