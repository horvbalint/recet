<script setup lang="ts">
import type { Recipe } from '~/pages/index.vue'
import { raw } from 'surrealdb'

defineOptions({ inheritAttrs: false })

const props = defineProps<{
  recipeId: Recipe['id']
}>()

const { data: recipe, status, error } = useAsyncData(`recipe-card-${props.recipeId}`, async () => {
  const [recipe] = await db.query<[Recipe]>(surql`SELECT ${raw(fieldsNeededForRecipeCard)} FROM ONLY ${props.recipeId}`)
  return recipe
})
</script>

<template>
  <div v-bind="$attrs">
    <neb-state-content :status="status" :error-description="error?.message">
      <recipe-card v-if="recipe" :recipe="recipe">
        <template #header-action>
          <slot name="header-action" />
        </template>
      </recipe-card>
    </neb-state-content>
  </div>
</template>
