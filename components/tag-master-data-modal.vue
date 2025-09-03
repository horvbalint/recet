<script setup lang="ts">
import type { InRecipeTag, OutRecipeTag } from '~/db'

defineProps<{
  initialData?: Partial<InRecipeTag> | null
}>()

const modelValue = defineModel<boolean>({ required: true })

const emit = defineEmits<{
  'saved': [item: OutRecipeTag]
}>()

// Recipe tag icon options (food and cooking related emojis)
const iconOptions = [
  '🍽️', '🍴', '🥄', '🔪', '🍳', '🥘', '🍲', '🥗', '🍝', '🍕',
  '🍔', '🌮', '🌯', '🥙', '🥪', '🍖', '🍗', '🥓', '🍤', '🐟',
  '🍎', '🍌', '🥕', '🥒', '🌶️', '🧄', '🧅', '🥑', '🍅', '🥔',
  '🌾', '🥖', '🍞', '🥐', '🧀', '🥛', '🍯', '🧂', '🍋', '🥥',
  '⏰', '🔥', '❄️', '⭐', '💚', '❤️', '🧡', '💛', '💜', '🤍',
  '👨‍🍳', '👩‍🍳', '🌿', '🌱', '♻️', '🌟', '✨', '💎', '🏆', '🎯'
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
    <template #form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
      
      <neb-select v-model="data.icon" label="Icon" :options="iconOptions" placeholder="Select an icon" required />
      
      <neb-input v-model="data.color" label="Color" type="color" required />
    </template>
  </master-data-modal>
</template>
