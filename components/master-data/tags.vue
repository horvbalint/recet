<script setup lang="ts">
import type { OutRecipeTag } from '~/db'

const { data, status, refresh } = await useAsyncData('tags', async () => {
  const [result] = await db.query<[OutRecipeTag[]]>(surql`SELECT * FROM recipe_tag ORDER BY name ASC`)
  return result || []
})

const columns = {
  name: { text: 'Name' },
  icon: { text: 'Icon' },
  color: { text: 'Color' }
}

// Recipe tag icon options (food and cooking related emojis)
const iconOptions = [
  '🍽️', '🍴', '🥄', '🔪', '🍳', '🥘', '🍲', '🥗', '🍝', '🍕',
  '🍔', '🌮', '🌯', '🥙', '🥪', '🍖', '🍗', '🥓', '🍤', '🐟',
  '🍎', '🍌', '🥕', '🥒', '🌶️', '🧄', '🧅', '🥑', '🍅', '🥔',
  '🌾', '🥖', '🍞', '🥐', '🧀', '🥛', '🍯', '🧂', '🍋', '🥥',
  '⏰', '🔥', '❄️', '⭐', '💚', '❤️', '🧡', '💛', '💜', '🤍',
  '👨‍🍳', '👩‍🍳', '🌿', '🌱', '♻️', '🌟', '✨', '💎', '🏆', '🎯'
]

async function handleCreate(formData: Record<string, any>) {
  try {
    await db.query(surql`CREATE recipe_tag CONTENT ${formData}`)
    await refresh()
  } catch (error) {
    console.error('Failed to create tag:', error)
  }
}
</script>

<template>
  <master-data-layout
    :data="data"
    :status="status"
    :refresh="refresh"
    :columns="columns"
    create-button-text="Add Tag"
    create-modal-title="Create New Tag"
    create-modal-icon="material-symbols:tag-rounded"
    :handle-create
  >
    <template #td-icon="{ original }">
      <span v-if="original" class="tag-icon">{{ original }}</span>
      <span v-else class="no-icon">—</span>
    </template>

    <template #td-color="{ original }">
      <div class="color-display">
        <div class="color-indicator" :style="{ background: original }"></div>
        <span class="color-value">{{ original }}</span>
      </div>
    </template>

    <template #modal-form="{ data }">
      <neb-input v-model="data.name" label="Name" required />
      
      <neb-select v-model="data.icon" label="Icon" :options="iconOptions" placeholder="Select an icon" required />
      
      <neb-input v-model="data.color" label="Color" type="color" required />
    </template>
  </master-data-layout>
</template>

<style scoped>
.color-display {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.color-indicator {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: 1px solid var(--neutral-color-200);
  flex-shrink: 0;
}

.color-value {
  font-family: monospace;
  font-size: var(--text-sm);
  color: var(--neutral-color-600);
}

.tag-icon {
  font-size: var(--text-lg);
}

.no-icon {
  color: var(--neutral-color-400);
  font-style: italic;
}
</style>
