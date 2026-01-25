<script setup lang="ts">
import type { OutMealPlan, OutMealRule, OutRecipe } from '~/db'
import dayjs from 'dayjs'
import isBetween from 'dayjs/plugin/isBetween'
import isSameOrAfter from 'dayjs/plugin/isSameOrAfter'
import isSameOrBefore from 'dayjs/plugin/isSameOrBefore'

dayjs.extend(isSameOrBefore)
dayjs.extend(isSameOrAfter)
dayjs.extend(isBetween)

// console.log(currentHousehold.value?.language)
// dayjs.locale(currentHousehold.value?.language || 'en')

const meals = ['breakfast', 'lunch', 'dinner', 'snack'] as const
type Meal = (typeof meals)[number]

const shownWeek = ref(dayjs())
const week = computed(() => {
  const startOfWeek = shownWeek.value.startOf('week')
  return Array.from({ length: 7 }).map((_, i) => startOfWeek.add(i, 'day'))
})

const { data: plansByDay, refresh } = useAsyncData(async () => {
  const [plans] = await db
    .query(surql`
      SELECT
        date,
        meals.breakfast.{recipe.{id, name}, servings},
        meals.lunch.{recipe.{id, name}, servings},
        meals.dinner.{recipe.{id, name}, servings},
        meals.snack.{recipe.{id, name}, servings}
      FROM meal_plan
      WHERE household = ${currentHousehold.value?.id} && date >= ${week.value[0]!.toDate()} && date <= ${week.value[6]!.toDate()} ORDER BY date ASC
    `)
    .collect<[OutMealPlan[]]>()

  const plansByDay: Record<string, OutMealPlan> = {}
  for (const plan of plans)
    plansByDay[dayjs(plan.date).format('YYYY-MM-DD')] = plan

  return plansByDay
}, {
  watch: [week, currentHousehold],
})

const isDragging = ref(false)
const selection = ref<{
  start: dayjs.Dayjs
  curr: dayjs.Dayjs
  meal: Meal
} | null>(null)

function startSelection(day: dayjs.Dayjs, meal: Meal) {
  isDragging.value = true
  selection.value = { start: day, curr: day, meal }
}

function updateSelection(day: dayjs.Dayjs) {
  if (!selection.value || !isDragging.value)
    return

  selection.value.curr = day
}

const ruleModal = ref(false)
watch(ruleModal, () => {
  if (!ruleModal.value)
    selection.value = null
})

window.addEventListener('mouseup', () => {
  if (!selection.value)
    return

  isDragging.value = false

  if (selection.value.start.isSame(selection.value.curr, 'day')) {
    selection.value = null
  }
  else {
    ruleModal.value = true
  }
})

const overWriteExistinMeals = ref(false)
const selectedRule = ref<OutMealRule | null>(null)
const { data: rules } = useAsyncData(async () => {
  const [rules] = await db
    .query(`SELECT * FROM meal_rule WHERE household = ${currentHousehold.value?.id} ORDER BY name ASC`)
    .collect<[OutMealRule[]]>()

  return rules
})

async function applyRule() {
  const startDay = selection.value!.start.isBefore(selection.value!.curr)
    ? selection.value!.start
    : selection.value!.curr
  const dayCount = Math.abs(selection.value!.start.diff(selection.value!.curr, 'day')) + 1

  const selectedDays = Array.from({ length: dayCount }).map((_, i) => startDay.add(i, 'day'))

  const query = surql`SELECT id FROM recipe`
  constructWhereClause(query, selectedRule.value!)
  query.append(surql`ORDER BY rand() LIMIT ${dayCount}`)

  const [recipes] = await db.query(query).collect<[Pick<OutRecipe, 'id'>[]]>()
  const enoughRecipes = recipes.length >= dayCount
    ? recipes
    : [...recipes, ...Array.from({ length: dayCount - recipes.length }).map((_, i) => recipes[i % recipes.length])]

  const mealDict = {
    breakfast: surql`breakfast`,
    lunch: surql`lunch`,
    dinner: surql`dinner`,
    snack: surql`snack`,
  }

  const promises = selectedDays.map((day, i) => {
    const recipeOperation = overWriteExistinMeals.value
      ? surql`= [{recipe: ${enoughRecipes[i]!.id}}]`
      : surql`+= {recipe: ${enoughRecipes[i]!.id}}`

    const query = surql`UPSERT meal_plan SET meals.`
    query.append(mealDict[selection.value!.meal])
    query.append(recipeOperation)
    query.append(surql`, date = ${day.toDate()}, household = ${currentHousehold.value?.id} WHERE household = ${currentHousehold.value?.id}  && date = ${day.toDate()}`)

    return db.query(query)
  })

  await Promise.all(promises)

  ruleModal.value = false
  overWriteExistinMeals.value = false
  selectedRule.value = null

  useNebToast({ type: 'success', title: 'Meal plan updated', description: 'The selected meal planning rule has been applied successfully.' })
  refresh()
}
</script>

<template>
  <page-layout>
    <template #content-header>
      <neb-content-header
        title="Meal planner"
        description="Plan your meals for the days ahead"
        :type="pageHeaderType"
        has-separator
      />
    </template>

    <div class="calendar">
      <div class="actions">
        <neb-button type="secondary" small @click="shownWeek = shownWeek.subtract(1, 'week')">
          Previous
        </neb-button>

        <neb-button type="secondary" small @click="shownWeek = shownWeek.add(1, 'week')">
          Next
        </neb-button>
      </div>

      <div class="week">
        <div />

        <header v-for="day in week" :key="day.toString()">
          {{ day.format('dddd MM/DD') }}
        </header>

        <template v-for="meal in meals" :key="`${meal}`">
          <p class="meal-label">
            {{ meal }}
          </p>

          <div
            v-for="day in week"
            :key="`${meal}-${day.toString()}`"
            :class="{ selected: selection?.meal === meal && day.isBetween(selection.start, selection.curr, 'day', '[]') }"
            class="meal"
            @mousedown="startSelection(day, meal)"
            @mouseover="updateSelection(day)"
          >
            <template v-if="plansByDay?.[day.format('YYYY-MM-DD')]">
              <div
                v-for="recipe in plansByDay[day.format('YYYY-MM-DD')]!.meals[meal]"
                :key="`${meal}-${day.toString()}-${recipe.recipe.id}`"
                class="recipe"
              >
                {{ recipe.recipe.name }} ({{ recipe.servings }})
              </div>
            </template>
          </div>
        </template>
      </div>
    </div>
  </page-layout>

  <neb-modal
    v-model="ruleModal"
    title="Select a rule"
    subtitle="Choose a meal planning rule to apply to the selected days"
    header-icon="material-symbols:rule-rounded"
  >
    <template #content>
      <neb-select
        v-model="selectedRule"
        :options="rules!"
        :label="`Select a rule for ${selection!.meal}`"
        label-key="name"
        track-by-key="id"
      />

      <neb-checkbox v-model="overWriteExistinMeals">
        Overwrite existing meals
      </neb-checkbox>
    </template>

    <template #actions>
      <neb-button type="primary" :disabled="!selectedRule" @click="applyRule()">
        Apply Rule
      </neb-button>
    </template>
  </neb-modal>
</template>

<style scoped>
.calendar {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  user-select: none;
}
.actions {
  display: flex;
  justify-content: space-between;
}
.week {
  flex: 1;
  display: grid;
  grid-template-columns: 50px repeat(7, 1fr);
  grid-template-rows: 50px repeat(4, 1fr);
}
.meal-label {
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  writing-mode: vertical-rl;
  transform: rotate(180deg);
  text-transform: capitalize;
}

header {
  padding: var(--spacing-2);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  text-transform: capitalize;
}

.meal {
  border: 1px solid var(--neutral-color);

  &.selected {
    background-color: var(--primary-color-100);
  }
}
</style>
