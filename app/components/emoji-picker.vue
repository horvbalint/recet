<script lang="ts" setup>
defineProps<{
  emojis: string[]
  label: string
  placeholder?: string
}>()

const modelValue = defineModel<string | null | undefined>()
</script>

<template>
  <neb-dropdown>
    <template #trigger="{ toggle }">
      <neb-content-header :title="label" vertical-gap="var(--space-2)" type="paragraph">
        <template #bottom>
          <neb-button class="trigger-button" small type="secondary-neutral" @click="toggle()">
            <div class="wrapper">
              <p v-if="modelValue" class="value">
                {{ modelValue }}
              </p>

              <p v-else class="placeholder">
                {{ placeholder }}
              </p>
            </div>
          </neb-button>
        </template>
      </neb-content-header>
    </template>

    <template #content="{ close }">
      <div class="emoji-grid">
        <neb-button
          v-for="emoji in emojis"
          :key="emoji"
          :type="emoji === modelValue ? 'secondary' : 'tertiary-neutral'"
          small
          @click="modelValue = emoji; close()"
        >
          {{ emoji }}
        </neb-button>
      </div>
    </template>
  </neb-dropdown>
</template>

<style scoped>
.trigger-button {
  flex: 1;

  .wrapper {
    height: 40px;
    display: flex;
    align-items: center;
  }

  .value {
    font-size: var(--text-xl);
  }

  .placeholder {
    color: var(--neutral-color-400);
    font-weight: normal;
  }
}
.emoji-grid {
  background: white;
  width: 250px;
  border: 1px solid var(--neutral-color-200);
  border-radius: var(--radius-default);
  box-shadow: var(--shadow-lg);
  display: grid;
  grid-template-columns: repeat(auto-fit, 40px);
  gap: var(--space-1);
  max-height: 250px;
  overflow-y: auto;
  padding: var(--space-2);

  button {
    font-size: var(--text-xl);
  }
}
</style>
