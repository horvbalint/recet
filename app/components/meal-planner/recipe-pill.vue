<script setup lang="ts">
import type { OutMealPlan } from '~/db'

defineProps<{
  recipe: OutMealPlan['meals']['breakfast'][number]
}>()
</script>

<template>
  <neb-dropdown
    full-width
  >
    <template #trigger="{ toggle }">
      <div class="recipe-item" @click="toggle()">
        <span class="recipe-name">{{ recipe.recipe.name }}</span>
        <span class="recipe-servings">{{ recipe.servings || 1 }}×</span>
      </div>
    </template>

    <template #content="{ isOpen }">
      <nuxt-link :to="`/recipe/${recipe.recipe.id.id}`" class="recipe-card">
        <recipe-card v-if="isOpen" :recipe-id="recipe.recipe.id" />
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
  background-color: var(--primary-color-50);
  border: 1px solid var(--primary-color-200);
  border-radius: var(--radius-default);
  font-size: var(--text-xs);
  transition: all 0.15s ease;
  text-decoration: none;

  &:hover {
    background-color: var(--primary-color-100);
    border-color: var(--primary-color-300);
  }

  .recipe-name {
    flex: 1;
    color: var(--primary-color-700);
    font-weight: 500;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .recipe-servings {
    color: var(--primary-color-600);
    font-weight: 600;
    font-size: var(--text-2xs);
    padding: 2px 4px;
    background-color: var(--primary-color-100);
    border-radius: var(--radius-small);
    white-space: nowrap;
  }
}
.recipe-card {
  width: 300px;
  text-decoration: none;
}

.dark-mode {
  .recipe-item {
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
  }
}
</style>
