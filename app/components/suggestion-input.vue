<script lang="ts" setup generic="LabelKey extends PropertyKey, T extends Option<LabelKey>">
import type { RecordId } from 'surrealdb'
import * as JsSearch from 'js-search'

export type Option<LabelKey extends PropertyKey> = {
  id: RecordId
} & {
  [labelKey in LabelKey]: PropertyKey
}

interface ProcessedOption {
  option: T
  trackValue: string
  labelValue: string
}

const props = withDefaults(defineProps<{
  options: T[]
  labelKey: LabelKey
  icon?: string
  onNew?: (value: string) => void
}>(), {
  icon: 'material-symbols:star-outline-rounded',
})

defineEmits<{
  new: [value: string]
}>()

const modelValue = defineModel<T | string | null | undefined>()

const processedOptions = computed<ProcessedOption[]>(() =>
  props.options.map(option => ({
    option,
    trackValue: option.id.id.toString(),
    labelValue: option[props.labelKey].toString(),
  })),
)

const searcher = computed(() => {
  const searcher = new JsSearch.Search('trackValue')
  searcher.addIndex('labelValue')
  searcher.addDocuments(processedOptions.value)

  return searcher
})

const inputText = ref(
  typeof modelValue.value === 'string'
    ? modelValue.value
    : modelValue.value
      ? modelValue.value[props.labelKey].toString()
      : '',
)
watch(inputText, () => modelValue.value = inputText.value)
watch(modelValue, () => {
  if (!modelValue.value)
    inputText.value = ''
  else if (typeof modelValue.value === 'string')
    inputText.value = modelValue.value
  else
    inputText.value = modelValue.value[props.labelKey].toString()
})

const dropwdown = useTemplateRef('dropwdown')

const suggestion = computed(() => {
  if (inputText.value.length < 2 || typeof modelValue.value !== 'string')
    return null

  dropwdown.value?.open()

  const [result] = searcher.value.search(inputText.value) as ProcessedOption[]
  return result || null
})

async function acceptSuggestion() {
  if (!suggestion.value)
    return

  inputText.value = suggestion.value.labelValue
  await nextTick()
  modelValue.value = suggestion.value.option
}

onMounted(() => dropwdown.value?.open())
</script>

<template>
  <neb-dropdown ref="dropwdown" full-width>
    <template #trigger>
      <neb-input v-model="inputText" v-bind="$attrs" @keyup.enter="acceptSuggestion()">
        <template #trailing>
          <neb-button v-if="onNew && inputText.length > 2 && typeof modelValue === 'string'" type="link" @click="$emit('new', inputText)">
            <Icon name="material-symbols:add-rounded" />
          </neb-button>

          <Icon v-else-if="typeof modelValue === 'object'" :name="icon" />
        </template>
      </neb-input>
    </template>

    <template #content>
      <div v-if="suggestion" class="dropdown">
        <neb-button type="link" @click="acceptSuggestion()">
          {{ suggestion.labelValue }}
        </neb-button>
      </div>
    </template>
  </neb-dropdown>
</template>

<style scoped>
.dropdown {
  padding: var(--space-2) var(--space-3);
  background: white;
  border: 1px solid var(--neutral-color-200);
  border-radius: var(--radius-default);
  box-shadow: var(--shadow-lg);
}

.dark-mode {
  .dropdown {
    background: var(--neutral-color-950);
    border: 1px solid var(--neutral-color-700);
  }
}
</style>
