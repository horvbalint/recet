<script setup lang="ts">
import type { InMealRule } from '~/db'

const props = defineProps<{
  initialData?: Partial<InMealRule> | null
}>()

defineEmits<{
  saved: [item: any]
}>()

const modelValue = defineModel<boolean>({ required: true })

const transformedInitialData = props.initialData
  ? {
      ...props.initialData,
      conditions: {
        include_operator: props.initialData.include_operator,
        include: props.initialData.include,
        exclude: props.initialData.exclude,
      },
    }
  : {
      conditions: createEmptyMealRuleConditions(),
    }

function transformBeforeSave(transformedData: any) {
  return {
    name: transformedData.name,
    include_operator: transformedData.conditions.include_operator,
    include: transformedData.conditions.include,
    exclude: transformedData.conditions.exclude,
  }
}

const { data: filterData, status: filterStatus, refresh: queryFilterData } = useFilterData()
watch(modelValue, () => {
  if (modelValue.value)
    queryFilterData()
}, { immediate: true })
</script>

<template>
  <master-data-modal
    v-model="modelValue"
    table="meal_rule"
    name="meal rule"
    icon="material-symbols:category-outline-rounded"
    :initial-data="transformedInitialData"
    :transform-before-create="transformBeforeSave"
    :transform-before-edit="transformBeforeSave"
    max-width="none"
    @saved="$emit('saved', $event)"
  >
    <template #form="{ data }">
      <neb-input
        v-model="data.name"
        label="Rule Name"
        placeholder="e.g., No Meat Mondays"
        required
      />

      <div class="filter-wrapper">
        <neb-content-header type="paragraph" title="Conditions" />

        <neb-state-content :status="filterStatus" :refresh="queryFilterData">
          <recipe-filter v-if="filterData" v-model="data.conditions" :filter-data="filterData" />
        </neb-state-content>
      </div>
    </template>
  </master-data-modal>
</template>

<style scoped>
.filter-wrapper {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}
</style>
