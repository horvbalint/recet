<script setup lang="ts">
definePageMeta({
  layout: 'app',
})

const { data: mealRules, status, refresh, error } = useAsyncData('meal-rules', async () => {
  const [mealRules] = await db
    .query(surql`
      SELECT
        *
      FROM
        meal_rule
      WHERE
        household = ${currentHousehold.value!.id}
      ORDER BY
        updated_at DESC
    `)
    .collect<[OutMealRule[]]>()

  return mealRules
}, { watch: [currentHousehold] })

const showCreateModal = ref(false)
</script>

<template>
  <page-layout>
    <template #content-header>
      <neb-content-header
        title="Meal Rules Management"
        description="Define and manage meal rules to customize your meal planning experience"
        :type="pageHeaderType"
        has-separator
      />
    </template>

    <neb-state-content :status :refresh :error-description="error?.message">
      <div class="meal-rules-page">
        <div v-if="mealRules?.length" class="rules-grid">
          <meal-rule-card
            v-for="rule in mealRules"
            :key="rule.id.toString()"
            :rule="rule"
            @view="openRule(rule.id)"
            @changed="refresh()"
          />
        </div>

        <neb-empty-state
          v-else
          icon="material-symbols:rule-rounded"
          title="No meal rules yet"
          description="Create your first rule to get started."
        >
          <neb-button type="primary" @click="showCreateModal = true">
            Create First Rule
          </neb-button>
        </neb-empty-state>
      </div>
    </neb-state-content>

    <meal-rule-modal
      v-model="showCreateModal"
      @change="handleRuleChange()"
    />
  </page-layout>
</template>

<style scoped>
.meal-rules-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.lists-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: var(--space-6);
}

@media (--tablet-viewport) {
  .lists-grid {
    grid-template-columns: 1fr;
    gap: var(--space-4);
  }
}
</style>
