<script setup lang="ts">
import type { InRecipeTag, OutRecipeTag } from '~/db'

defineProps<{
  initialData?: Partial<InRecipeTag> | null
}>()

const emit = defineEmits<{
  saved: [item: OutRecipeTag]
}>()

const modelValue = defineModel<boolean>({ required: true })

const emojis = [
  '🍽️',
  '🍴',
  '🥄',
  '🔪',
  '🍳',
  '🥘',
  '🍲',
  '🥗',
  '🍝',
  '🍕',
  '🍔',
  '🌮',
  '🌯',
  '🥙',
  '🥪',
  '🍖',
  '🍗',
  '🥓',
  '🍤',
  '🐟',
  '🍎',
  '🍌',
  '🥕',
  '🥒',
  '🌶️',
  '🧄',
  '🧅',
  '🥑',
  '🍅',
  '🥔',
  '🌾',
  '🥖',
  '🍞',
  '🥐',
  '🧀',
  '🥛',
  '🍯',
  '🧂',
  '🍋',
  '🥥',
  '⏰',
  '🔥',
  '❄️',
  '⭐',
  '💚',
  '❤️',
  '🧡',
  '💛',
  '💜',
  '🤍',
  '👨‍🍳',
  '👩‍🍳',
  '🌿',
  '🌱',
  '♻️',
  '🌟',
  '✨',
  '💎',
  '🏆',
  '🎯',
]

function handleSave(item: OutRecipeTag) {
  emit('saved', item)
}
</script>

<template>
  <master-data-modal
    v-model="modelValue"
    table="recipe_tag"
    name="tag"
    icon="material-symbols:tag-rounded"
    :initial-data
    @saved="handleSave"
  >
    <template #form="{ data, isFormValid }">
      <neb-input v-model="data.name" label="Name" required />

      <div class="flex-row">
        <neb-input v-model="data.color" label="Color" type="color" required />

        <emoji-picker
          v-model="data.icon"
          label="Icon"
          :emojis
          placeholder="Select an icon"
        />
        <!-- <neb-select v-model="data.icon" no-search label="Icon" :options="iconOptions" placeholder="Select an icon" /> -->
      </div>

      <neb-content-header v-if="isFormValid" title="Preview" type="paragraph" vertical-gap="var(--space-2)">
        <template #bottom>
          <recipe-tag-badge :tag="data as InRecipeTag" />
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
