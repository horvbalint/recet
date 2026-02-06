<script setup lang="ts">
const route = useRoute()
const recipeId = route.params.id as string

await db.signin({
  access: 'recipe_guest',
  variables: {
    recipe_id: recipeId,
  },
})
</script>

<template>
  <page-layout>
    <recipe-page :recipe-id="recipeId" guest />
  </page-layout>
</template>
