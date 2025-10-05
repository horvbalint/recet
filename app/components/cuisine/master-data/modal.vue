<script setup lang="ts">
import type { InCuisine, OutCuisine } from '~/db'

defineProps<{
  initialData?: Partial<InCuisine> | null
}>()

const emit = defineEmits<{
  saved: [item: OutCuisine]
}>()

const modelValue = defineModel<boolean>({ required: true })

const flagOptions = [
  '🇺🇸',
  '🇬🇧',
  '🇫🇷',
  '🇮🇹',
  '🇪🇸',
  '🇩🇪',
  '🇯🇵',
  '🇨🇳',
  '🇮🇳',
  '🇰🇷',
  '🇹🇭',
  '🇻🇳',
  '🇲🇽',
  '🇧🇷',
  '🇦🇷',
  '🇵🇪',
  '🇨🇦',
  '🇦🇺',
  '🇷🇺',
  '🇺🇦',
  '🇵🇱',
  '🇨🇿',
  '🇭🇺',
  '🇷🇴',
  '🇬🇷',
  '🇹🇷',
  '🇪🇬',
  '🇲🇦',
  '🇿🇦',
  '🇳🇬',
  '🇮🇱',
  '🇱🇧',
  '🇸🇦',
  '🇦🇪',
  '🇮🇷',
  '🇵🇰',
  '🇧🇩',
  '🇱🇰',
  '🇳🇵',
  '🇲🇾',
  '🇸🇬',
  '🇮🇩',
  '🇵🇭',
  '🇰🇭',
  '🇱🇦',
  '🇲🇲',
  '🇪🇹',
  '🇰🇪',
  '🇬🇭',
  '🇨🇮',
  '🇦🇹',
  '🇧🇪',
  '🇨🇭',
  '🇩🇰',
  '🇫🇮',
  '🇮🇸',
  '🇮🇪',
  '🇱🇺',
  '🇳🇱',
  '🇳🇴',
  '🇵🇹',
  '🇸🇪',
  '🇭🇷',
  '🇧🇬',
  '🇷🇸',
  '🇸🇮',
  '🇸🇰',
  '🇲🇰',
  '🇦🇱',
  '🇧🇦',
  '🇲🇪',
  '🇲🇩',
  '🇱🇹',
  '🇱🇻',
  '🇪🇪',
  '🇧🇾',
  '🇬🇪',
  '🇦🇲',
  '🇦🇿',
  '🇰🇿',
  '🇺🇿',
  '🇹🇯',
  '🇰🇬',
  '🇹🇲',
  '🇲🇳',
  '🇦🇫',
  '🇯🇴',
  '🇸🇾',
  '🇮🇶',
  '🇾🇪',
  '🇴🇲',
  '🇶🇦',
  '🇰🇼',
  '🇧🇭',
  '🇹🇳',
  '🇩🇿',
  '🇱🇾',
  '🇸🇩',
  '🇨🇺',
  '🇯🇲',
  '🇭🇹',
  '🇩🇴',
  '🇵🇷',
  '🇨🇱',
  '🇺🇾',
  '🇵🇾',
  '🇧🇴',
  '🇪🇨',
  '🇨🇴',
  '🇻🇪',
  '🇬🇾',
  '🇸🇷',
  '🇨🇷',
  '🇵🇦',
  '🇳🇮',
  '🇭🇳',
  '🇬🇹',
  '🇧🇿',
  '🇸🇻',
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
    <template #form="{ data, isFormValid }">
      <neb-input v-model="data.name" label="Name" required />

      <div class="flex-row">
        <neb-input v-model="data.color" label="Color" type="color" required />

        <emoji-picker
          v-model="data.flag"
          label="Flag"
          :emojis="flagOptions"
          placeholder="Select a flag"
        />
      </div>

      <neb-content-header v-if="isFormValid" title="Preview" type="paragraph" vertical-gap="var(--space-2)">
        <template #bottom>
          <cuisine-badge :cuisine="data as InCuisine" />
        </template>
      </neb-content-header>
    </template>
  </master-data-modal>
</template>

<style scoped>
.flex-row {
  display: flex;
  gap: var(--space-2);
}
</style>
