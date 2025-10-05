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

const suggestion = computed(() => {
  if (inputText.value.length < 2 || typeof modelValue.value !== 'string')
    return null

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

const input = useTemplateRef('input')
watch(inputText, () => {
  if (!input.value?.input)
    return

  if (!inputText.value.length)
    input.value.input.style.width = '100%'
  else
    input.value.input.style.width = `${inputText.value.length}ch`
})
</script>

<template>
  <neb-input
    ref="input"
    v-model="inputText"
    class="suggestion-input"
    :class="{ 'has-suggestion': !!suggestion }"
    v-bind="$attrs"
    @keyup.tab="acceptSuggestion()"
  >
    <template #trailing>
      <div class="trailing">
        <neb-button
          v-if="onNew && !!inputText.length && typeof modelValue === 'string'"
          type="link"
          small
          @click="$emit('new', inputText)"
        >
          <Icon name="material-symbols:add-rounded" />
        </neb-button>

        <Icon v-else-if="typeof modelValue === 'object'" :name="icon" />

        <div v-if="suggestion" class="suggestion">
          <neb-tag small>
            <Icon name="material-symbols:keyboard-tab-rounded" />

            <p @click="acceptSuggestion()">
              {{ suggestion.labelValue }}
            </p>
          </neb-tag>
        </div>
      </div>
    </template>
  </neb-input>
  <!-- <neb-dropdown ref="dropwdown" full-width>
    <template #trigger>

    </template>

    <template #content>
      <div v-if="suggestion" class="dropdown">
        <neb-button type="link" @click="acceptSuggestion()">
          {{ suggestion.labelValue }}
        </neb-button>
      </div>
    </template>
  </neb-dropdown> -->
</template>

<style scoped>
.suggestion-input {
  :deep(.input) {
    min-width: unset;
    justify-content: space-between;
  }

  &.has-suggestion {
    :deep(.input) {
      input {
        flex: unset;
      }
    }

    .trailing {
      flex: 1;
    }
  }
}
.trailing {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-direction: row-reverse;
  gap: var(--space-2);

  .icon {
    font-size: 22px !important;
  }
}
.suggestion {
  display: flex;
  align-items: center;
  gap: var(--space-1);

  p,
  .icon {
    color: var(--neutral-color-500);
    font-size: var(--text-xs) !important;
    user-select: none;
  }
}
</style>
