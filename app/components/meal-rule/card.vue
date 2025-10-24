<script setup lang="ts">
import dayjs from 'dayjs'
import relativeTime from 'dayjs/plugin/relativeTime'

const props = defineProps<{
  rule: OutMealRule
}>()

const emit = defineEmits<{
  view: []
  changed: []
}>()

dayjs.extend(relativeTime)

const showEditModal = ref(false)

const menuItems = [
  {
    text: 'Edit',
    icon: 'material-symbols:edit-outline-rounded',
    callback: () => showEditModal.value = true,
  },
  {
    text: 'Delete',
    icon: 'material-symbols:delete-outline-rounded',
    desctructive: true,
    callback: () => deleteList(),
  },
]

async function handleRuleChange() {
  showEditModal.value = false
  emit('changed')
}

async function deleteList() {
  try {
    if (!await useNebConfirm({ title: 'Confirm deletion!', description: 'Are you sure you want to delete this meal rule? This action cannot be undone.' }))
      return

    await db
      .query(surql`DELETE ${props.rule.id}`)
      .collect()
    useNebToast({ type: 'success', title: 'Rule deleted', description: 'Meal rule has been deleted.' })
    emit('changed')
  }
  catch (error) {
    console.error('Error deleting list:', error)
    useNebToast({ type: 'error', title: 'Delete failed', description: 'Could not delete the meal rule.' })
  }
}
</script>

<template>
  <div class="rule-card" @click="emit('view')">
    <div class="rule-header">
      <div class="rule-header-texts">
        <h3 class="rule-name">
          {{ props.rule.name }}
        </h3>

        <div class="rule-stats">
          <neb-badge small>
            {{ props.rule.items.length }} items
          </neb-badge>

          <span class="updated-time">{{ dayjs(props.rule.updated_at).fromNow() }}</span>
        </div>
      </div>

      <neb-menu :menus="menuItems" :floating-options="{ placement: 'bottom-end' }" @click.stop>
        <template #trigger="{ toggle }">
          <neb-button
            type="tertiary-neutral"
            small
            @click="toggle()"
          >
            <icon name="material-symbols:more-vert" />
          </neb-button>
        </template>
      </neb-menu>
    </div>

    <div class="rule-actions">
      <neb-button type="secondary" small>
        View List
      </neb-button>
    </div>
  </div>

  <meal-rule-modal v-if="showEditModal" v-model="showEditModal" :initial-data="{ ...rule, shop: rule.shop?.id }" @change="handleRuleChange()" />
</template>

<style scoped>
.rule-card {
  background: #fff;
  border-radius: var(--radius-large);
  border: 1px solid var(--neutral-color-200);
  box-shadow: var(--shadow-sm);
  padding: var(--space-5);
  cursor: pointer;
  transition: all var(--duration-default);
  display: flex;
  flex-direction: column;
  gap: var(--space-8);
}

.rule-card:hover {
  box-shadow: var(--shadow-md);
  border-color: var(--primary-color-200);
}

.rule-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: var(--space-4);
}

.rule-header-texts {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.rule-name {
  font-size: var(--text-lg);
  font-weight: var(--font-semibold);
  color: var(--neutral-color-900);
  margin: 0;
}

.rule-stats {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.updated-time {
  font-size: var(--text-sm);
  color: var(--neutral-color-500);
}

.rule-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}

@media (--tablet-viewport) {
  .rule-card {
    padding: var(--space-4);
  }
}

/* Dark mode support */
.dark-mode {
  .rule-card {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);
  }

  .rule-card:hover {
    border-color: var(--primary-color-600);
  }

  .rule-name {
    color: var(--neutral-color-100);
  }

  .updated-time {
    color: var(--neutral-color-400);
  }
}
</style>
