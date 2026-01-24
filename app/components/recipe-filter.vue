<script setup lang="ts">
import type { InMealRuleConditions } from '~/db'

defineProps<{
  filterData: ReturnType<typeof useFilterData>['data']['value']
}>()

const modelValue = defineModel<InMealRuleConditions>({ required: true })
const advancedMode = ref(false)

const filledGroupCount = computed(() => {
  const inc = modelValue.value.include
  return Number(!!inc.meals.items.length) + Number(!!inc.tags.items.length) + Number(!!inc.cuisines.items.length) + Number(!!inc.ingredients.items.length)
})

const hasExcludeFilters = computed(() => {
  return modelValue.value.exclude.meals.length
    || modelValue.value.exclude.tags.length
    || modelValue.value.exclude.cuisines.length
    || modelValue.value.exclude.ingredients.length
})

watch(advancedMode, (isAdvanced) => {
  if (!isAdvanced) {
    modelValue.value.include_operator = 'and'
    modelValue.value.include.meals.operator = 'or'
    modelValue.value.include.tags.operator = 'or'
    modelValue.value.include.cuisines.operator = 'or'
    modelValue.value.include.ingredients.operator = 'or'

    if (modelValue.value.exclude.meals.length)
      modelValue.value.exclude.meals = []
    if (modelValue.value.exclude.tags.length)
      modelValue.value.exclude.tags = []
    if (modelValue.value.exclude.cuisines.length)
      modelValue.value.exclude.cuisines = []
    if (modelValue.value.exclude.ingredients.length)
      modelValue.value.exclude.ingredients = []
  }
})

watch(hasExcludeFilters, (has) => {
  if (has)
    advancedMode.value = true
}, {
  immediate: true,
})
</script>

<template>
  <div v-if="filterData" class="recipe-filter">
    <div class="filter-section" :class="{ simple: !advancedMode }">
      <neb-expand :when="advancedMode">
        <div class="section-header">
          <h4 class="section-title">
            <icon name="material-symbols:check-circle-outline-rounded" />
            Include
          </h4>

          <div v-if="filledGroupCount > 1" class="top-operator">
            <match-operator-toggle v-model="modelValue.include_operator" />
          </div>
        </div>
      </neb-expand>

      <div class="filter-groups">
        <div class="filter-group">
          <neb-expand :when="advancedMode">
            <div class="filter-group-header">
              <span class="filter-label">Meals</span>
              <match-operator-toggle v-if="modelValue.include.meals.items.length > 1" v-model="modelValue.include.meals.operator" />
            </div>
          </neb-expand>

          <neb-select
            v-model="modelValue.include.meals.items"
            placeholder="Filter by meal type"
            :options="filterData.meals"
            label-key="name"
            track-by-key="id"
            :transform-fun="transformId"
            use-only-tracked-key
            multiple
            leading-icon="material-symbols:restaurant-rounded"
          >
            <template #option="{ option }">
              <meal-badge :meal="option" />
            </template>

            <template #selection="{ selected }">
              <meal-badge v-for="meal in selected" :key="meal.trackValue.toString()" small :meal="meal.option" />
            </template>
          </neb-select>
        </div>

        <div class="filter-group">
          <neb-expand :when="advancedMode">
            <div class="filter-group-header">
              <span class="filter-label">Tags</span>
              <match-operator-toggle v-if="modelValue.include.tags.items.length > 1" v-model="modelValue.include.tags.operator" />
            </div>
          </neb-expand>

          <neb-select
            v-model="modelValue.include.tags.items"
            placeholder="Filter by tag"
            :options="filterData.tags"
            label-key="name"
            track-by-key="id"
            :transform-fun="transformId"
            use-only-tracked-key
            multiple
            leading-icon="material-symbols:tag-rounded"
          >
            <template #option="{ option }">
              <recipe-tag-badge :tag="option" />
            </template>

            <template #selection="{ selected }">
              <recipe-tag-badge v-for="tag in selected" :key="tag.trackValue.toString()" small :tag="tag.option" />
            </template>
          </neb-select>
        </div>

        <div class="filter-group">
          <neb-expand :when="advancedMode">
            <span class="filter-label">Cuisines</span>
          </neb-expand>

          <neb-select
            v-model="modelValue.include.cuisines.items"
            placeholder="Filter by cuisine"
            :options="filterData.cuisines"
            label-key="name"
            track-by-key="id"
            :transform-fun="transformId"
            use-only-tracked-key
            multiple
            leading-icon="material-symbols:public"
          >
            <template #option="{ option }">
              <cuisine-badge :cuisine="option" />
            </template>

            <template #selection="{ selected }">
              <cuisine-badge v-for="cuisine in selected" :key="cuisine.trackValue.toString()" small :cuisine="cuisine.option" />
            </template>
          </neb-select>
        </div>

        <div class="filter-group">
          <neb-expand :when="advancedMode">
            <div class="filter-group-header">
              <span class="filter-label">Ingredients</span>
              <match-operator-toggle v-if="modelValue.include.ingredients.items.length > 1" v-model="modelValue.include.ingredients.operator" />
            </div>
          </neb-expand>

          <neb-select
            v-model="modelValue.include.ingredients.items"
            placeholder="Filter by ingredient"
            :options="filterData.ingredients"
            label-key="name"
            track-by-key="id"
            :transform-fun="transformId"
            use-only-tracked-key
            multiple
            leading-icon="material-symbols:grocery"
          />
        </div>
      </div>
    </div>

    <neb-expand :when="advancedMode">
      <div class="filter-section exclude">
        <div class="section-header">
          <h4 class="section-title">
            <icon name="material-symbols:cancel-outline-rounded" />
            Exclude
          </h4>
        </div>

        <div class="filter-groups">
          <neb-select
            v-model="modelValue.exclude.meals"
            label="Meals"
            placeholder="None excluded"
            :options="filterData.meals"
            label-key="name"
            track-by-key="id"
            :transform-fun="transformId"
            use-only-tracked-key
            multiple
            leading-icon="material-symbols:restaurant-rounded"
          >
            <template #option="{ option }">
              <meal-badge :meal="option" />
            </template>

            <template #selection="{ selected }">
              <meal-badge v-for="meal in selected" :key="meal.trackValue.toString()" small :meal="meal.option" />
            </template>
          </neb-select>

          <neb-select
            v-model="modelValue.exclude.tags"
            label="Tags"
            placeholder="None excluded"
            :options="filterData.tags"
            label-key="name"
            track-by-key="id"
            :transform-fun="transformId"
            use-only-tracked-key
            multiple
            leading-icon="material-symbols:tag-rounded"
          >
            <template #option="{ option }">
              <recipe-tag-badge :tag="option" />
            </template>

            <template #selection="{ selected }">
              <recipe-tag-badge v-for="tag in selected" :key="tag.trackValue.toString()" small :tag="tag.option" />
            </template>
          </neb-select>

          <neb-select
            v-model="modelValue.exclude.cuisines"
            label="Cuisines"
            placeholder="None excluded"
            :options="filterData.cuisines"
            label-key="name"
            track-by-key="id"
            :transform-fun="transformId"
            use-only-tracked-key
            multiple
            leading-icon="material-symbols:public"
          >
            <template #option="{ option }">
              <cuisine-badge :cuisine="option" />
            </template>

            <template #selection="{ selected }">
              <cuisine-badge v-for="cuisine in selected" :key="cuisine.trackValue.toString()" small :cuisine="cuisine.option" />
            </template>
          </neb-select>

          <neb-select
            v-model="modelValue.exclude.ingredients"
            label="Ingredients"
            placeholder="None excluded"
            :options="filterData.ingredients"
            label-key="name"
            track-by-key="id"
            :transform-fun="transformId"
            use-only-tracked-key
            multiple
            leading-icon="material-symbols:grocery"
          />
        </div>
      </div>
    </neb-expand>

    <neb-button small type="link-neutral" @click="advancedMode = !advancedMode">
      <template v-if="advancedMode">
        <icon name="material-symbols:keyboard-arrow-up-rounded" />
        Hide advanced options
      </template>
      <template v-else>
        <icon name="material-symbols:keyboard-arrow-down-rounded" />
        Show advanced options
      </template>
    </neb-button>
  </div>
</template>

<style scoped>
.recipe-filter {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.filter-section {
  padding: var(--space-4);
  border-radius: var(--radius-default);
  background-color: var(--neutral-color-50);
  border: 1px solid var(--neutral-color-200);
  transition:
    padding var(--duration-default) ease,
    background-color var(--duration-default) ease,
    border-color var(--duration-default) ease;
}

.filter-section.simple {
  background-color: transparent;
  border-width: 0px;
  padding: 0;
}

.filter-section.exclude {
  background-color: var(--error-color-50);
  border-color: var(--error-color-200);
  max-height: 100%;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  flex-wrap: wrap;
  margin-bottom: var(--space-4);
}

.section-title {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--neutral-color-800);
  margin: 0;
}

.filter-section.exclude .section-title {
  color: var(--error-color-600);
}

.top-operator {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.operator-label {
  font-size: var(--text-sm);
  color: var(--neutral-color-600);
}

.exclude-hint {
  font-size: var(--text-sm);
  color: var(--neutral-color-500);
  font-style: italic;
}

.filter-groups {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  gap: var(--space-4);

  & > * {
    flex: 1;
  }
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  flex: 1;
  min-width: 200px;
}

.filter-group-header {
  display: flex;
  align-items: end;
  justify-content: space-between;
  gap: var(--space-2);
}

.filter-label {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--neutral-color-800);
}

.dark-mode {
  .filter-section {
    background-color: var(--neutral-color-900);
    border-color: var(--neutral-color-700);
  }

  .filter-section.exclude {
    background-color: color-mix(in srgb, var(--error-color-900) 30%, var(--neutral-color-900));
    border-color: var(--error-color-800);
  }

  .section-title {
    color: var(--neutral-color-200);
  }

  .filter-section.exclude .section-title {
    color: var(--error-color-400);
  }

  .operator-label {
    color: var(--neutral-color-400);
  }

  .exclude-hint {
    color: var(--neutral-color-500);
  }

  .filter-label {
    color: var(--neutral-color-300);
  }
}
</style>
