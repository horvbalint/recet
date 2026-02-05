<script setup lang="ts">
import type { Recipe } from '~/pages/index.vue'
import { raw } from 'surrealdb'

const props = defineProps<{
  recipeId?: Recipe['id']
  recipe?: Recipe
}>()

if (!props.recipeId && !props.recipe)
  throw new Error('Either recipeId or recipe prop must be provided to RecipeCard component.')

const recipeId = props.recipeId || props.recipe!.id

const { data: recipe, status, error } = useAsyncData(`recipe-card-${recipeId}`, async () => {
  if (props.recipe)
    return props.recipe

  const [recipe] = await db.query<[Recipe]>(surql`SELECT ${raw(fieldsNeededForRecipeCard)} FROM ONLY ${recipeId}`)
  return recipe
}, {
  getCachedData(key, nuxt) {
    return nuxt.payload.data[key]
  },
})

async function handleCardClick() {
  setCachedRecipe(recipe.value!)

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
    <neb-state-content :status="status" :error-description="error?.message">
      <recipe-image :recipe="recipe!" :width-px="400" :height-px="200">
        <slot name="header-action" />
      </recipe-image>

      <div class="recipe-content">
        <div class="recipe-content-inner-wrapper">
          <div class="recipe-header">
            <h3 class="recipe-title">
              {{ recipe!.name }}
            </h3>
          </div>

          <div class="recipe-meta">
            <div class="meta-item">
              <icon name="material-symbols:grocery" />
              <span>{{ recipe!.ingredients }} ingredients</span>
            </div>

            <div class="meta-item">
              <icon name="material-symbols:format-list-numbered-rounded" />
              <span>{{ recipe!.steps }} steps</span>
            </div>

            <div v-if="recipe!.cooking_time_minutes" class="meta-item">
              <icon name="material-symbols:schedule-outline-rounded" />
              <span>{{ recipe!.cooking_time_minutes }} min</span>
            </div>
          </div>
        </div>

        <div class="recipe-content-inner-wrapper">
          <div v-if="recipe!.tags?.length" class="recipe-tags">
            <recipe-tag-badge v-for="tag in recipe!.tags" :key="tag.name" :tag />
          </div>

          <div v-if="recipe!.meal?.length" class="meal-types">
            <meal-badge v-for="meal in recipe!.meal" :key="meal.name" small :meal />
          </div>
        </div>
      </div>
    </neb-state-content>
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
  color: var(--neutral-color-900);
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
