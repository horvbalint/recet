<script setup lang="ts">
import type { OutShoppingList } from '~/db'
import dayjs from 'dayjs'
import relativeTime from 'dayjs/plugin/relativeTime'

defineProps<{
  list: OutShoppingList
}>()

const emit = defineEmits<{
  view: []
}>()

dayjs.extend(relativeTime)

function handleClick() {
  emit('view')
}
</script>

<template>
  <div class="list-card" @click="handleClick()">
    <div class="list-header">
      <h3 class="list-name">
        {{ list.name }}
      </h3>

      <div class="list-stats">
        <neb-badge small>
          {{ list.items.length }} items
        </neb-badge>

        <span class="updated-time">{{ dayjs(list.updated_at).fromNow() }}</span>
      </div>
    </div>

    <div class="list-actions">
      <neb-button type="secondary" size="small">
        View List
      </neb-button>
    </div>
  </div>
</template>

<style scoped>
.list-card {
  background: #fff;
  border-radius: var(--radius-large);
  border: 1px solid var(--neutral-color-200);
  box-shadow: var(--shadow-sm);
  padding: var(--space-5);
  cursor: pointer;
  transition: all var(--duration-default);
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.list-card:hover {
  box-shadow: var(--shadow-md);
  border-color: var(--primary-color-200);
}

.list-header {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.list-name {
  font-size: var(--text-lg);
  font-weight: var(--font-semibold);
  color: var(--neutral-color-900);
  margin: 0;
}

.list-stats {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.updated-time {
  font-size: var(--text-sm);
  color: var(--neutral-color-500);
}

.list-actions {
  display: flex;
  justify-content: flex-end;
}

@media (--tablet-viewport) {
  .list-card {
    padding: var(--space-4);
  }
}
</style>
