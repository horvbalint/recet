<script setup lang="ts">
import type { Recipe } from '~/pages/index.vue'

const props = defineProps<{
  recipe: Recipe
}>()

const recipeId = props.recipe.id

async function handleCardClick() {
  setCachedRecipe(props.recipe)

  await nextTick()
  startTransitionThen(() => navigateTo(`/recipe/${recipeId.id}`))
}

function handleMiddleClick() {
  navigateTo(`/recipe/${recipeId.id}`, {
    open: {
      target: '_blank',
    },
  })
}
</script>

<template>
  <div class="recipe-card" @click="handleCardClick()" @click.middle="handleMiddleClick()">
    <recipe-image :recipe="recipe" :width-px="400" :height-px="200">
      <slot name="header-action" />
    </recipe-image>

    <div class="recipe-content">
      <div class="recipe-content-inner-wrapper">
        <div class="recipe-header">
          <h3 class="recipe-title">
            {{ recipe.name }}
          </h3>
        </div>

        <div class="recipe-meta">
          <div class="meta-item">
            <icon name="material-symbols:grocery" />
            <span>{{ $t('recipes.card.ingredients', { count: recipe.ingredients }) }}</span>
          </div>

          <div v-if="recipe.recipes" class="meta-item">
            <icon name="material-symbols:menu-book-outline-rounded" />
            <span>{{ $t('recipes.card.recipes', { count: recipe.recipes }) }}</span>
          </div>

          <div class="meta-item">
            <icon name="material-symbols:format-list-numbered-rounded" />
            <span>{{ $t('recipes.card.steps', { count: recipe.steps }) }}</span>
          </div>

          <div v-if="recipe.cooking_time_minutes" class="meta-item">
            <icon name="material-symbols:schedule-outline-rounded" />
            <span>{{ recipe.cooking_time_minutes }} {{ $t('common.minutes') }}</span>
          </div>
        </div>
      </div>

      <div class="recipe-content-inner-wrapper">
        <div v-if="recipe.tags?.length" class="recipe-tags">
          <recipe-tag-badge v-for="tag in recipe.tags" :key="tag.name" :tag />
        </div>

        <div v-if="recipe.meal?.length" class="meal-types">
          <meal-badge v-for="meal in recipe.meal" :key="meal.name" small :meal />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.recipe-card {
  background: var(--neb-bg-raised);
  border-radius: var(--radius-default);
  box-shadow: var(--neb-shadow-sm);
  overflow: hidden;
  transition: all var(--duration-default);
  cursor: pointer;
  border: 1px solid var(--neb-border-subtle);
}

.recipe-card:hover {
  box-shadow: var(--neb-shadow-md);
  transform: translateY(-2px);
  border-color: var(--neb-border);
}

.image-placeholder {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, var(--neb-bg-muted), var(--neb-bg-subtle));
  display: flex;
  align-items: center;
  justify-content: center;
}

.image-placeholder .icon {
  font-size: 48px !important;
  color: var(--neb-text-subtle);
}

.recipe-content {
  padding: var(--space-5);
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.recipe-content-inner-wrapper {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.recipe-header {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.recipe-title {
  font-size: var(--text-xl);
  font-weight: 600;
  color: var(--neb-text);
  margin: 0;
  line-height: 1.3;
  width: fit-content;
}

.recipe-meta {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-3);
  width: fit-content;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-sm);
  color: var(--neb-text-muted);
  font-weight: 500;
}

.meta-item .icon {
  font-size: 18px !important;
  color: var(--neb-text-subtle);
}

.recipe-tags {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-1);
  align-items: center;
  width: fit-content;
}

.meal-types {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-1);
  width: fit-content;
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
</style>
