<script setup lang="ts">
import type { RecordId } from 'surrealdb'
import type { InMealRule, OutMealPlan, OutMealRule, OutRecipe } from '~/db'
import dayjs from 'dayjs'
import isBetween from 'dayjs/plugin/isBetween'
import isSameOrAfter from 'dayjs/plugin/isSameOrAfter'
import isSameOrBefore from 'dayjs/plugin/isSameOrBefore'
import { and, eq, raw, Table } from 'surrealdb'

dayjs.extend(isSameOrBefore)
dayjs.extend(isSameOrAfter)
dayjs.extend(isBetween)

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
        id,
        date,
        meals.breakfast.{recipe.{id, name}, servings, state},
        meals.lunch.{recipe.{id, name}, servings, state},
        meals.dinner.{recipe.{id, name}, servings, state},
        meals.snack.{recipe.{id, name}, servings, state}
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

window.addEventListener('click', () => {
  if (!selection.value || ruleModal.value)
    return

  isDragging.value = false

  if (selection.value.start.isSame(selection.value.curr, 'day')) {
    openDayEditModal(selection.value.start, selection.value.meal)
    selection.value = null
  }
  else {
    ruleModal.value = true
  }
})

const overWriteExistinMeals = ref(false)
const selectedRule = ref<OutMealRule | null>(null)
const createRuleModal = ref(false)
const createRuleInitialName = ref('')

const { data: rules, refresh: refreshRules } = useAsyncData(async () => {
  const [rules] = await db
    .query(`SELECT * FROM meal_rule WHERE household = ${currentHousehold.value?.id} ORDER BY name ASC`)
    .collect<[OutMealRule[]]>()

  return rules
})

function handleCreateRule(searchTerm: string) {
  createRuleInitialName.value = searchTerm
  createRuleModal.value = true
}

async function onRuleCreated(rule: OutMealRule) {
  await refreshRules()
  selectedRule.value = rule
}

async function applyRule() {
  const startDay = selection.value!.start.isBefore(selection.value!.curr) ? selection.value!.start : selection.value!.curr
  const dayCount = Math.abs(selection.value!.start.diff(selection.value!.curr, 'day')) + 1

  const selectedDays = Array.from({ length: dayCount }).map((_, i) => startDay.add(i, 'day'))

  const whereConditions = constructWhereConditions(selectedRule.value!)
  const query = surql`SELECT id FROM recipe WHERE ${whereConditions} ORDER BY rand() LIMIT ${dayCount}`

  const [recipes] = await db.query(query).collect<[Pick<OutRecipe, 'id'>[]]>()
  const enoughRecipes = recipes.length >= dayCount
    ? recipes
    : [...recipes, ...Array.from({ length: dayCount - recipes.length }).map((_, i) => recipes[i % recipes.length])]

  const promises = selectedDays.map((day, i) => {
    const mealsOperator = overWriteExistinMeals.value ? '=' : '+='
    const arrayStart = overWriteExistinMeals.value ? '[' : ``
    const arrayEnd = overWriteExistinMeals.value ? ']' : ``

    return db.query(surql`
      UPSERT
        meal_plan
      SET
        meals.${raw(selection.value!.meal)} ${raw(mealsOperator)} ${raw(arrayStart)}{ recipe: ${enoughRecipes[i]!.id}, servings: 1, state: 'todo' }${raw(arrayEnd)},
        household = ${currentHousehold.value?.id},
        date = ${day.toDate()}
      WHERE
        household = ${currentHousehold.value?.id}
        && date = ${day.toDate()}
    `)
  })

  await Promise.all(promises)

  ruleModal.value = false
  overWriteExistinMeals.value = false
  selectedRule.value = null
  selection.value = null

  useNebToast({ type: 'success', title: 'Meal plan updated', description: 'The selected meal planning rule has been applied successfully.' })
  refresh()
}

const { data: recipes } = useAsyncData(async () => {
  const [recipes] = await db
    .query(surql`SELECT id, name FROM recipe WHERE household = ${currentHousehold.value?.id} ORDER BY name ASC`)
    .collect<[Pick<OutRecipe, 'id' | 'name'>[]]>()

  return recipes
}, {
  watch: [currentHousehold],
})

interface MealItem {
  recipe: RecordId<'recipe'> | null
  servings: number
}

const dayEditModal = ref(false)
const editingDay = ref<dayjs.Dayjs | null>(null)
const editingMeal = ref<Meal | null>(null)
const editingMeals = ref<MealItem[]>([])

function openDayEditModal(day: dayjs.Dayjs, meal: Meal) {
  editingDay.value = day
  editingMeal.value = meal

  const dayKey = day.format('YYYY-MM-DD')
  const existingPlan = plansByDay.value?.[dayKey]

  if (existingPlan?.meals[meal]?.length) {
    editingMeals.value = existingPlan.meals[meal].map(item => ({
      recipe: item.recipe.id,
      servings: item.servings ?? 1,
    }))
  }
  else {
    editingMeals.value = []
  }

  dayEditModal.value = true
}

watch(dayEditModal, () => {
  if (!dayEditModal.value) {
    editingDay.value = null
    editingMeal.value = null
    editingMeals.value = []
  }
})

function openRuleModalForSingleDay() {
  selection.value = {
    start: editingDay.value!,
    curr: editingDay.value!,
    meal: editingMeal.value!,
  }
  dayEditModal.value = false
  ruleModal.value = true
}

const formValid = ref(false)
const savingDayEdit = ref(false)
async function saveDayMeals() {
  if (!editingDay.value || !editingMeal.value)
    return

  savingDayEdit.value = true

  try {
    await db
      .upsert(new Table('meal_plan'))
      .merge({
        meals: {
          [editingMeal.value]: editingMeals.value,
        },
        household: currentHousehold.value?.id,
        date: editingDay.value.toDate(),
      })
      .where(and(
        eq('household', currentHousehold.value?.id),
        eq('date', editingDay.value.toDate()),
      ))

    dayEditModal.value = false
    useNebToast({ type: 'success', title: 'Meals saved', description: 'Your meal plan has been updated.' })
    refresh()
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Save failed', description: 'Could not save the meals. Please try again.' })
  }
  finally {
    savingDayEdit.value = false
  }
}

type RecipeState = OutMealPlan['meals']['breakfast'][number]['state']

async function updateRecipeState(day: dayjs.Dayjs, meal: Meal, recipeIndex: number, state: RecipeState) {
  const dayKey = day.format('YYYY-MM-DD')
  const mealPlan = plansByDay.value![dayKey]!

  try {
    await db.query(surql`UPDATE ${mealPlan.id} SET meals.${raw(meal)}[${raw(recipeIndex.toString())}].state = ${state}`)
    refresh()
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Update failed', description: 'Could not update the recipe state.' })
  }
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
        <neb-button type="tertiary-neutral" small @click="shownWeek = shownWeek.subtract(1, 'week')">
          <icon name="material-symbols:chevron-left-rounded" />
        </neb-button>

        <span class="week-label">{{ week[0]!.format('YYYY, MMM D') }} - {{ week[6]!.format('MMM D') }}</span>

        <neb-button type="tertiary-neutral" small @click="shownWeek = shownWeek.add(1, 'week')">
          <icon name="material-symbols:chevron-right-rounded" />
        </neb-button>
      </div>

      <div class="desktop-view">
        <div />

        <header v-for="day in week" :key="day.toString()" :class="{ today: day.isSame(dayjs(), 'day') }">
          <span class="day-name">{{ day.format('ddd') }}</span>
          <span class="day-number">{{ day.format('D') }}</span>
        </header>

        <template v-for="meal in meals" :key="`${meal}`">
          <p class="meal-label">
            {{ meal }}
          </p>

          <div
            v-for="day in week"
            :key="`${meal}-${day.toString()}`"
            :class="{
              selected: selection?.meal === meal && day.isBetween(selection.start, selection.curr, 'day', '[]'),
              today: day.isSame(dayjs(), 'day'),
            }"
            class="meal"
            @mousedown="startSelection(day, meal)"
            @mouseover="updateSelection(day)"
          >
            <template v-if="plansByDay?.[day.format('YYYY-MM-DD')]">
              <meal-planner-recipe-pill
                v-for="(recipe, recipeIndex) in plansByDay[day.format('YYYY-MM-DD')]!.meals[meal]"
                :key="`${meal}-${day.toString()}-${recipe.recipe.id}`"
                :recipe
                @mousedown.stop
                @click.stop
                @update-state="updateRecipeState(day, meal, recipeIndex, $event)"
              />
            </template>
          </div>
        </template>
      </div>

      <div class="mobile-view">
        <div v-for="day in week" :key="day.toString()" class="day-card">
          <header class="day-card-header">
            <span class="day-name">{{ day.format('ddd') }}</span>
            <span class="day-number">{{ day.format('D') }}</span>
          </header>

          <div class="day-card-meals">
            <div v-for="meal in meals" :key="`mobile-${meal}-${day.toString()}`" class="day-card-meal" @click="openDayEditModal(day, meal)">
              <span class="meal-title">{{ meal }}</span>

              <div class="meal-recipes">
                <template v-if="plansByDay?.[day.format('YYYY-MM-DD')]?.meals[meal]?.length">
                  <meal-planner-recipe-pill
                    v-for="(recipe, recipeIndex) in plansByDay[day.format('YYYY-MM-DD')]!.meals[meal]"
                    :key="`${meal}-${day.toString()}-${recipe.recipe.id}`"
                    :recipe
                    @mousedown.stop
                    @click.stop
                    @update-state="updateRecipeState(day, meal, recipeIndex, $event)"
                  />
                </template>

                <span v-else class="no-recipes">No recipes</span>
              </div>
            </div>
          </div>
        </div>
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
        :label="`Select a rule for ${selection?.meal}`"
        label-key="name"
        track-by-key="id"
        :on-new="handleCreateRule"
        @new="handleCreateRule($event)"
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

  <neb-modal
    v-model="dayEditModal"
    :title="`Edit ${editingMeal} - ${editingDay?.format('dddd, MMM D')}`"
    subtitle="Add, edit, or remove recipes for this meal"
    header-icon="material-symbols:edit-calendar-rounded"
  >
    <template #content>
      <neb-validator v-model="formValid">
        <neb-form-list
          v-model="editingMeals"
          :factory="() => ({ recipe: null, servings: 1, state: 'todo' })"
        >
          <template #default="{ item }">
            <div class="meal-edit-item">
              <neb-select
                v-model="item.recipe"
                :options="recipes!"
                label="Recipe"
                label-key="name"
                track-by-key="id"
                placeholder="Select recipe"
                :transform-fun="transformId"
                use-only-tracked-key
                required
              />

              <neb-input
                v-model="item.servings"
                label="Servings"
                type="number"
                :min="1"
                placeholder="1"
              />
            </div>
          </template>

          <template #actions>
            <neb-button type="tertiary-neutral" @click="openRuleModalForSingleDay()">
              Add by rule
            </neb-button>
          </template>
        </neb-form-list>
      </neb-validator>
    </template>

    <template #actions>
      <neb-button type="primary" :disabled="!formValid || savingDayEdit" :loading="savingDayEdit" @click="saveDayMeals()">
        Save
      </neb-button>
    </template>
  </neb-modal>

  <meal-rule-master-data-modal
    v-if="createRuleModal"
    v-model="createRuleModal"
    :initial-data="{ name: createRuleInitialName, ...createEmptyMealRuleConditions() }"
    @saved="onRuleCreated"
  />
</template>

<style scoped>
.calendar {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  user-select: none;
}

.actions {
  display: flex;
  justify-content: center;
  gap: var(--space-8);
  align-items: center;
}

.week-label {
  font-size: var(--text-lg);
  font-weight: 600;
}

.desktop-view {
  height: 100%;
  display: grid;
  grid-template-columns: 50px repeat(7, minmax(0, 1fr));
  grid-template-rows: auto repeat(4, minmax(0, 1fr));
  gap: var(--space-1);
}

.mobile-view {
  display: none;
}

.meal-label {
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 500;
  font-size: var(--text-xs);
  letter-spacing: 0.05em;
  writing-mode: vertical-rl;
  transform: rotate(180deg);
  text-transform: uppercase;
  color: var(--neutral-color-700);
  padding: var(--space-2) 0;
}

header {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2px;
  padding: var(--space-2) 0;
  font-size: var(--text-xs);
  color: var(--neutral-color-700);

  &.today {
    color: var(--primary-color-600);
  }

  .day-name {
    text-transform: uppercase;
    font-weight: 500;
    font-size: var(--text-2xs);
    letter-spacing: 0.05em;
  }

  .day-number {
    font-size: var(--text-lg);
    font-weight: 600;
  }
}

.meal {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
  padding: var(--space-2);
  border: 1px solid var(--neutral-color-200);
  border-radius: var(--radius-small);
  transition:
    background-color 0.15s ease,
    border-color 0.15s ease;
  cursor: pointer;

  &:hover {
    background-color: var(--neutral-color-50);
    border-color: var(--neutral-color-300);
  }

  &.selected {
    background-color: var(--primary-color-100);
    border-color: var(--primary-color-300);
  }
  &.today {
    border-color: var(--primary-color-300);
  }
}

.meal-edit-item {
  display: flex;
  gap: var(--space-3);
  align-items: flex-start;
  flex-wrap: wrap;

  & > :first-child {
    flex: 1;
  }

  & > :last-child {
    width: 100px;
  }
}

.dark-mode {
  .calendar {
    border-color: var(--neutral-color-800);
  }

  .meal-label {
    color: var(--neutral-color-300);
  }

  header {
    color: var(--neutral-color-300);

    &.today {
      color: var(--primary-color-500);
    }
  }

  .meal {
    border-color: var(--neutral-color-700);

    &:hover {
      background-color: var(--neutral-color-900);
      border-color: var(--neutral-color-600);
    }

    &.selected {
      background-color: var(--primary-color-900);
      border-color: var(--primary-color-700);
    }

    &.today {
      border-color: var(--primary-color-700);
    }
  }
}

@media (--tablet-viewport) {
  .desktop-view {
    display: none;
  }

  .mobile-view {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .day-card {
    border: 1px solid var(--neutral-color-200);
    border-radius: var(--radius-large);
  }

  .day-card-header {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-3);
    background-color: var(--neutral-color-50);
    border-bottom: 1px solid var(--neutral-color-200);
    color: var(--neutral-color-700);

    .day-name {
      text-transform: uppercase;
      font-weight: 600;
      font-size: var(--text-xs);
      letter-spacing: 0.05em;
    }

    .day-number {
      font-size: var(--text-lg);
      font-weight: 700;
    }
  }

  .day-card-meals {
    display: flex;
    flex-direction: column;
  }

  .day-card-meal {
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
    padding: var(--space-3);
    cursor: pointer;
    transition: background-color 0.15s ease;

    &:not(:last-child) {
      border-bottom: 1px solid var(--neutral-color-100);
    }

    &:hover {
      background-color: var(--neutral-color-50);
    }
  }

  .meal-title {
    text-transform: capitalize;
    font-weight: 600;
    font-size: var(--text-xs);
    color: var(--neutral-color-700);
  }

  .meal-recipes {
    display: flex;
    flex-direction: column;
    gap: var(--space-1);
  }

  .no-recipes {
    font-size: var(--text-xs);
    color: var(--neutral-color-400);
    font-style: italic;
  }
  .meal-edit-item {
    & > :last-child {
      width: 100%;
    }
  }

  .dark-mode {
    .day-card {
      border-color: var(--neutral-color-700);
    }
    .day-card-header {
      color: var(--neutral-color-300);
      background-color: var(--neutral-color-900);
      border-color: var(--neutral-color-700);
    }
    .day-card-meal {
      border-color: var(--neutral-color-700);

      &:hover {
        background-color: var(--neutral-color-800);
      }
      &:not(:last-child) {
        border-color: var(--neutral-color-800);
      }
    }
    .meal-title {
      color: var(--neutral-color-300);
    }
  }
}
</style>
