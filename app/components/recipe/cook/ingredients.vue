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
        class="ingredient"
      >
        <span v-if="ingredient.amount" class="amount">{{ roundNumberIfNeeded(ingredient.amount * portionRatio) }}</span>
        <span v-if="ingredient.unit" class="unit">{{ ingredient.unit }}</span>
        <span>{{ ingredient.ingredient }}</span>
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
  gap: var(--space-3);
  align-items: flex-start;
}

.ingredient {
  .amount,
  .unit {
    font-weight: 600;
    color: var(--neb-text);
  }
}
</style>
