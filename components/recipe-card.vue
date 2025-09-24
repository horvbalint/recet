<script setup lang="ts">
import type { Recipe } from '~/pages/index.vue'

const props = defineProps<{
  recipe: Recipe
}>()

function getEstimatedTime(stepCount: number) {
  if (stepCount <= 3)
    return '15-30 min'
  if (stepCount <= 6)
    return '30-45 min'
  if (stepCount <= 10)
    return '45-60 min'
  return '60+ min'
}

function handleCardClick() {
  navigateTo(`/recipe/${props.recipe.id.id}`)
}
</script>

<template>
  <div class="recipe-card" @click="handleCardClick()">
    <recipe-image :recipe="recipe" :width-px="400" :height-px="200" />

    <div class="recipe-content">
      <div class="recipe-header">
        <h3 class="recipe-title">
          {{ recipe.name }}
        </h3>
      </div>

      <div class="recipe-meta">
        <div class="meta-item">
          <icon name="material-symbols:grocery" />
          <span>{{ recipe.ingredients }} ingredients</span>
        </div>

        <div class="meta-item">
          <icon name="material-symbols:format-list-numbered-rounded" />
          <span>{{ recipe.steps }} steps</span>
        </div>

        <div class="meta-item">
          <icon name="material-symbols:schedule-outline-rounded" />
          <span>{{ getEstimatedTime(recipe.steps) }}</span>
        </div>
      </div>

      <div v-if="recipe.tags?.length" class="recipe-tags">
        <badge-tag v-for="tag in recipe.tags" :key="tag.name" :tag />
      </div>

      <div v-if="recipe.meal?.length" class="meal-types">
        <badge-meal v-for="meal in recipe.meal" :key="meal.name" small :meal />
      </div>
    </div>
  </div>
</template>

<style scoped>
.recipe-card {
  background: #fff;
  border-radius: var(--radius-default);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
  transition: all var(--duration-default);
  cursor: pointer;
  border: 1px solid var(--neutral-color-100);
}

.recipe-card:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
  border-color: var(--neutral-color-200);
}

.image-placeholder {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, var(--neutral-color-100), var(--neutral-color-50));
  display: flex;
  align-items: center;
  justify-content: center;
}

.image-placeholder .icon {
  font-size: 48px !important;
  color: var(--neutral-color-400);
}

.cuisine-badge {
  position: absolute;
  top: var(--space-3);
  right: var(--space-3);
}

.recipe-content {
  padding: var(--space-5);
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.recipe-header {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.recipe-title {
  font-size: var(--text-xl);
  font-weight: 600;
  color: var(--neutral-color-900);
  margin: 0;
  line-height: 1.3;
}

.recipe-meta {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-4);
}

.meta-item {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-sm);
  color: var(--neutral-color-600);
  font-weight: 500;
}

.meta-item .icon {
  font-size: 18px !important;
  color: var(--neutral-color-500);
}

.recipe-tags {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  align-items: center;
}

.meal-types {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

@media (--tablet-viewport) {
  .recipe-card {
    border-radius: var(--radius-default);
  }
}

@media (--mobile-viewport) {
  .recipe-content {
    padding: var(--space-4);
  }

  .recipe-meta {
    gap: var(--space-3);
  }

  .meta-item {
    font-size: var(--text-xs);
  }
}

.dark-mode {
  .recipe-card {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);
  }

  .recipe-card:hover {
    border-color: var(--neutral-color-700);
  }

  .recipe-title {
    color: var(--neutral-color-100);
  }

  .meta-item {
    color: var(--neutral-color-400);
  }

  .meta-item .icon {
    color: var(--neutral-color-500);
  }

  .image-placeholder {
    background: linear-gradient(135deg, var(--neutral-color-800), var(--neutral-color-900));
  }
}
</style>
