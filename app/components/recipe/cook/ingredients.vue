<script setup lang="ts">
import type { RecordId } from 'surrealdb'

export interface CookIngredient {
  ingredient: string
  amount?: number
  unit?: string
  description?: string
}

export interface CookSubRecipe {
  recipe: {
    id: RecordId<'recipe'>
    name: string
  }
  description?: string
}

defineProps<{
  ingredients?: CookIngredient[]
  subRecipes?: CookSubRecipe[]
  portionRatio: number
}>()

const portions = defineModel<number | undefined>('portions')
const checked = defineModel<number[]>('checked', { required: true })

function decrementPortions() {
  if (portions.value && portions.value >= 2)
    portions.value -= 1
}

function incrementPortions() {
  if (portions.value)
    portions.value += 1
}
</script>

<template>
  <section class="cook-ingredients">
    <neb-content-header :title="$t('recipes.cook.ingredients')" type="section">
      <template v-if="portions" #actions>
        <div class="portion-controls">
          <neb-button small square type="tertiary-neutral" @click="decrementPortions()">
            <icon name="material-symbols:remove-rounded" />
          </neb-button>

          {{ portions }}

          <neb-button small square type="tertiary-neutral" @click="incrementPortions()">
            <icon name="material-symbols:add-rounded" />
          </neb-button>
        </div>
      </template>
    </neb-content-header>

    <div class="ingredient-list">
      <neb-badge v-for="subRecipe in subRecipes" :key="subRecipe.recipe.id.id.toString()">
        {{ subRecipe.recipe.name }}
      </neb-badge>

      <neb-checkbox
        v-for="(ingredient, index) in ingredients"
        :key="index"
        v-model="checked"
        :value="index"
        class="ingredient-item"
      >
        <div class="ingredient-content">
          <div class="ingredient-details">
            <span v-if="ingredient.amount" class="ingredient-amount">{{ roundNumberIfNeeded(ingredient.amount * portionRatio) }}</span>
            <span v-if="ingredient.unit" class="ingredient-unit">{{ ingredient.unit }}</span>
            <span class="ingredient-name">{{ ingredient.ingredient }}</span>
          </div>

          <div v-if="ingredient.description" class="ingredient-description">
            {{ ingredient.description }}
          </div>
        </div>
      </neb-checkbox>
    </div>
  </section>
</template>

<style scoped>
.cook-ingredients {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.portion-controls {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.ingredient-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.ingredient-item {
  gap: var(--space-3);
  padding: var(--space-3);
  border: 1px solid var(--neb-border-subtle);
  border-radius: var(--radius-default);
  transition: all var(--duration-default);
}

.ingredient-item:hover {
  background: var(--neb-bg-hover);
  border-color: var(--neb-border);
}

.ingredient-content {
  display: flex;
  flex-direction: column;
  flex: 1;
  gap: var(--space-1);
  font-size: var(--text-md);
  font-weight: normal;
  cursor: text;
  user-select: text;
}

.ingredient-details {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex: 1;
}

.ingredient-amount {
  font-weight: 600;
  color: var(--neb-text);
}

.ingredient-unit {
  color: var(--neb-text-muted);
  font-size: var(--text-sm);
}

.ingredient-name {
  color: var(--neb-text);
  flex: 1;
}

.ingredient-description {
  color: var(--neb-text-subtle);
  font-size: var(--text-sm);
  font-style: italic;
}
</style>
