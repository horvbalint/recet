<script setup lang="ts">
const route = useRoute()
const recipeId = route.params.id as string

onBeforeRouteLeave((to, _, next) => {
  if (to.path !== '/')
    return next()

  startTransitionThen(next)
})
</script>

<template>
  <page-layout>
    <recipe-page :recipe-id="recipeId" :is-guest="!isCurrHouseholdEditor" />
  </page-layout>
</template>
