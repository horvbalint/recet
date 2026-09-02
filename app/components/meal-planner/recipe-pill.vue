<script setup lang="ts">
import type { OutMealPlan } from '~/db'

const props = defineProps<{
  recipe: OutMealPlan['meals']['breakfast'][number]
}>()
const emit = defineEmits<{
  updateState: [state: MealState]
}>()
const { t } = useI18n()
type MealState = OutMealPlan['meals']['breakfast'][number]['state']

const stateOptions: MealState[] = ['todo', 'prepared', 'done', 'served']

const stateLabels = computed<Record<MealState, string>>(() => ({
  todo: t('mealPlanner.recipeState.todo'),
  prepared: t('mealPlanner.recipeState.prepared'),
  done: t('mealPlanner.recipeState.done'),
  served: t('mealPlanner.recipeState.served'),
}))

const stateColors = {
  todo: 'info',
  prepared: 'warning',
  done: 'primary',
  served: 'success',
} as const

function updateState(state: MealState) {
  emit('updateState', state)
}

function cycleState() {
  const currentIndex = stateOptions.indexOf(props.recipe.state)
  const nextIndex = (currentIndex + 1) % stateOptions.length
  updateState(stateOptions[nextIndex]!)
}
</script>

<template>
  <neb-dropdown full-width>
    <template #trigger="{ toggle }">
      <div class="recipe-item" :class="props.recipe.state" @click="toggle()">
        <span class="recipe-name">{{ props.recipe.recipe.name }}</span>
        <span class="recipe-servings">{{ props.recipe.servings || 1 }}×</span>
      </div>
    </template>

    <template #content="{ isOpen }">
      <recipe-card v-if="isOpen" :recipe-id="props.recipe.recipe.id" class="recipe-card">
        <template #header-action>
          <div class="state-badge-wrapper">
            <neb-badge
              :color="stateColors[props.recipe.state]"
              class="state-badge"
              @click.stop.prevent="cycleState()"
            >
              {{ stateLabels[props.recipe.state] }}
            </neb-badge>
          </div>
        </template>
      </recipe-card>
    </template>
  </neb-dropdown>
</template>

<style scoped>
.recipe-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
  padding: var(--space-1);
  border-radius: var(--radius-default);
  font-size: var(--text-xs);
  transition: all 0.15s ease;
  text-decoration: none;

  &.todo {
    background-color: var(--neb-bg-muted);
    border: 1px solid var(--neb-border-subtle);

    &:hover {
      background-color: var(--neb-bg-active);
      border-color: var(--neb-border);
    }

    .recipe-name {
      color: var(--neb-text);
    }
    .recipe-servings {
      color: var(--neb-text-muted);
      background-color: var(--neb-bg-muted);
    }
    .state-icon {
      color: var(--neb-text-subtle);
    }
  }

  &.prepared {
    background-color: var(--neb-bg-warning-subtle);
    border: 1px solid var(--neb-border-warning);

    &:hover {
      background-color: var(--neb-bg-warning-hover);
      border-color: var(--neb-border-warning-strong);
    }

    .recipe-name {
      color: var(--neb-text-warning);
    }
    .recipe-servings {
      color: var(--neb-text-warning);
      background-color: var(--neb-bg-warning);
    }
    .state-icon {
      color: var(--neb-text-warning);
    }
  }

  &.done {
    background-color: var(--neb-bg-primary-subtle);
    border: 1px solid var(--neb-border-primary);

    &:hover {
      background-color: var(--neb-bg-primary-hover);
      border-color: var(--neb-border-primary-strong);
    }

    .recipe-name {
      color: var(--neb-text-primary);
    }
    .recipe-servings {
      color: var(--neb-text-primary);
      background-color: var(--neb-bg-primary);
    }
    .state-icon {
      color: var(--neb-text-primary);
    }
  }

  &.served {
    background-color: var(--neb-bg-success-subtle);
    border: 1px solid var(--neb-border-success);

    &:hover {
      background-color: var(--neb-bg-success-hover);
      border-color: var(--neb-border-success-strong);
    }

    .recipe-name {
      color: var(--neb-text-success);
    }
    .recipe-servings {
      color: var(--neb-text-success);
      background-color: var(--neb-bg-success);
    }
    .state-icon {
      color: var(--neb-text-success);
    }
  }

  .state-icon {
    font-size: 14px !important;
    flex-shrink: 0;
  }

  .recipe-name {
    flex: 1;
    font-weight: 500;
  }

  .recipe-servings {
    font-weight: 600;
    font-size: var(--text-xs);
    padding: 2px 4px;
    border-radius: var(--radius-small);
  }
}

.recipe-card {
  width: 300px;
  text-decoration: none;
}

.state-badge-wrapper {
  position: absolute;
  top: var(--space-2);
  left: var(--space-2);
}

.state-badge {
  cursor: pointer;
  transition: transform 0.15s ease;
}

.state-badge:hover {
  transform: scale(1.05);
}
</style>
