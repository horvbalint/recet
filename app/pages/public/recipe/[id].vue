<script setup lang="ts">
const route = useRoute()
const recipeId = route.params.id as string
</script>

<template>
  <page-layout>
    <recipe-page :recipe-id="recipeId" is-guest />
  </page-layout>
</template>
