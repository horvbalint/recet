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
            {{ $t('filter.include') }}
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
              <span class="filter-label">{{ $t('filter.meals.label') }}</span>
              <match-operator-toggle v-if="modelValue.include.meals.items.length > 1" v-model="modelValue.include.meals.operator" />
            </div>
          </neb-expand>

          <neb-select
            v-model="modelValue.include.meals.items"
            :placeholder="$t('filter.meals.placeholder')"
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
              <span class="filter-label">{{ $t('filter.tags.label') }}</span>
              <match-operator-toggle v-if="modelValue.include.tags.items.length > 1" v-model="modelValue.include.tags.operator" />
            </div>
          </neb-expand>

          <neb-select
            v-model="modelValue.include.tags.items"
            :placeholder="$t('filter.tags.placeholder')"
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
            <span class="filter-label">{{ $t('filter.cuisines.label') }}</span>
          </neb-expand>

          <neb-select
            v-model="modelValue.include.cuisines.items"
            :placeholder="$t('filter.cuisines.placeholder')"
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
              <span class="filter-label">{{ $t('filter.ingredients.label') }}</span>
              <match-operator-toggle v-if="modelValue.include.ingredients.items.length > 1" v-model="modelValue.include.ingredients.operator" />
            </div>
          </neb-expand>

          <neb-select
            v-model="modelValue.include.ingredients.items"
            :placeholder="$t('filter.ingredients.placeholder')"
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
            {{ $t('filter.exclude') }}
          </h4>
        </div>

        <div class="filter-groups">
          <neb-select
            v-model="modelValue.exclude.meals"
            :label="$t('filter.meals.label')"
            :placeholder="$t('filter.noneExcluded')"
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
            :label="$t('filter.tags.label')"
            :placeholder="$t('filter.noneExcluded')"
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
            :label="$t('filter.cuisines.label')"
            :placeholder="$t('filter.noneExcluded')"
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
            :label="$t('filter.ingredients.label')"
            :placeholder="$t('filter.noneExcluded')"
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
        {{ $t('filter.hideAdvanced') }}
      </template>
      <template v-else>
        <icon name="material-symbols:keyboard-arrow-down-rounded" />
        {{ $t('filter.showAdvanced') }}
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
  background-color: var(--neb-bg-subtle);
  border: 1px solid var(--neb-border);
  transition:
    padding var(--duration-default) ease,
    background-color var(--duration-default) ease,
    border-color var(--duration-default) ease;
}

.filter-section.simple {
  background: none;
  border-width: 0px;
  padding: 0;
}

.filter-section.exclude {
  background-color: var(--neb-bg-error-subtle);
  border-color: var(--neb-border-error);
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
  color: var(--neb-text);
  margin: 0;
}

.filter-section.exclude .section-title {
  color: var(--neb-text-error);
}

.top-operator {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.operator-label {
  font-size: var(--text-sm);
  color: var(--neb-text-muted);
}

.exclude-hint {
  font-size: var(--text-sm);
  color: var(--neb-text-subtle);
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
  color: var(--neb-text);
}
</style>
