<script setup lang="ts">
import type { OutMealPlan } from '~/db'

type MealState = OutMealPlan['meals']['breakfast'][number]['state']

const props = defineProps<{
  recipe: OutMealPlan['meals']['breakfast'][number]
}>()

const emit = defineEmits<{
  updateState: [state: MealState]
}>()

const stateOptions: MealState[] = ['todo', 'prepared', 'done', 'served']

const stateLabels: Record<MealState, string> = {
  todo: 'To do',
  prepared: 'Prepared',
  done: 'Done',
  served: 'Served',
}

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
  updateState(stateOptions[nextIndex])
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
      <nuxt-link :to="`/recipe/${props.recipe.recipe.id.id}`" class="recipe-card">
        <recipe-card v-if="isOpen" :recipe-id="props.recipe.recipe.id">
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
      </nuxt-link>
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
    background-color: var(--neutral-color-100);
    border: 1px solid var(--neutral-color-200);

    &:hover {
      background-color: var(--neutral-color-200);
      border-color: var(--neutral-color-300);
    }

    .recipe-name {
      color: var(--neutral-color-700);
    }
    .recipe-servings {
      color: var(--neutral-color-600);
      background-color: var(--neutral-color-200);
    }
    .state-icon {
      color: var(--neutral-color-500);
    }
  }

  &.prepared {
    background-color: var(--warning-color-50);
    border: 1px solid var(--warning-color-200);

    &:hover {
      background-color: var(--warning-color-100);
      border-color: var(--warning-color-300);
    }

    .recipe-name {
      color: var(--warning-color-700);
    }
    .recipe-servings {
      color: var(--warning-color-600);
      background-color: var(--warning-color-100);
    }
    .state-icon {
      color: var(--warning-color-500);
    }
  }

  &.done {
    background-color: var(--primary-color-50);
    border: 1px solid var(--primary-color-200);

    &:hover {
      background-color: var(--primary-color-100);
      border-color: var(--primary-color-300);
    }

    .recipe-name {
      color: var(--primary-color-700);
    }
    .recipe-servings {
      color: var(--primary-color-600);
      background-color: var(--primary-color-100);
    }
    .state-icon {
      color: var(--primary-color-500);
    }
  }

  &.served {
    background-color: var(--success-color-50);
    border: 1px solid var(--success-color-200);

    &:hover {
      background-color: var(--success-color-100);
      border-color: var(--success-color-300);
    }

    .recipe-name {
      color: var(--success-color-700);
    }
    .recipe-servings {
      color: var(--success-color-600);
      background-color: var(--success-color-100);
    }
    .state-icon {
      color: var(--success-color-500);
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
    font-size: var(--text-2xs);
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

.dark-mode {
  .recipe-item {
    &.todo {
      background-color: var(--neutral-color-800);
      border-color: var(--neutral-color-700);

      &:hover {
        background-color: var(--neutral-color-700);
        border-color: var(--neutral-color-600);
      }

      .recipe-name {
        color: var(--neutral-color-200);
      }
      .recipe-servings {
        color: var(--neutral-color-300);
        background-color: var(--neutral-color-700);
      }
      .state-icon {
        color: var(--neutral-color-400);
      }
    }

    &.prepared {
      background-color: var(--warning-color-900);
      border-color: var(--warning-color-800);

      &:hover {
        background-color: var(--warning-color-800);
        border-color: var(--warning-color-700);
      }

      .recipe-name {
        color: var(--warning-color-200);
      }
      .recipe-servings {
        color: var(--warning-color-300);
        background-color: var(--warning-color-800);
      }
      .state-icon {
        color: var(--warning-color-400);
      }
    }

    &.done {
      background-color: var(--primary-color-900);
      border-color: var(--primary-color-800);

      &:hover {
        background-color: var(--primary-color-800);
        border-color: var(--primary-color-700);
      }

      .recipe-name {
        color: var(--primary-color-200);
      }
      .recipe-servings {
        color: var(--primary-color-300);
        background-color: var(--primary-color-800);
      }
      .state-icon {
        color: var(--primary-color-400);
      }
    }

    &.served {
      background-color: var(--success-color-900);
      border-color: var(--success-color-800);

      &:hover {
        background-color: var(--success-color-800);
        border-color: var(--success-color-700);
      }

      .recipe-name {
        color: var(--success-color-200);
      }
      .recipe-servings {
        color: var(--success-color-300);
        background-color: var(--success-color-800);
      }
      .state-icon {
        color: var(--success-color-400);
      }
    }
  }
}
</style>
