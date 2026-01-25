<script setup lang="ts">
import { ref } from 'vue'
import { IconReact, IconSvelte, IconVue } from '../icons'

type Framework = 'react' | 'vue' | 'svelte'

defineProps<{
  modelValue: Framework
}>()

const emit = defineEmits<{
  'update:modelValue': [value: Framework]
}>()

const tabsRef = ref<HTMLElement | null>(null)

const frameworks: { id: Framework; label: string; file: string }[] = [
  { id: 'react', label: 'React', file: 'users/index.tsx' },
  { id: 'vue', label: 'Vue', file: 'users/index.vue' },
  { id: 'svelte', label: 'Svelte', file: 'users/index.svelte' },
]

const select = (id: Framework) => {
  emit('update:modelValue', id)
}

const handleKeydown = (event: KeyboardEvent, currentIndex: number) => {
  let newIndex = currentIndex

  if (event.key === 'ArrowLeft' || event.key === 'ArrowUp') {
    event.preventDefault()
    newIndex = currentIndex === 0 ? frameworks.length - 1 : currentIndex - 1
  } else if (event.key === 'ArrowRight' || event.key === 'ArrowDown') {
    event.preventDefault()
    newIndex = currentIndex === frameworks.length - 1 ? 0 : currentIndex + 1
  } else if (event.key === 'End') {
    event.preventDefault()
    newIndex = frameworks.length - 1
  } else if (event.key === 'Home') {
    event.preventDefault()
    newIndex = 0
  } else {
    return
  }

  emit('update:modelValue', frameworks[newIndex].id)

  // Use component-scoped ref instead of global document query
  const tabs = tabsRef.value?.querySelectorAll<HTMLButtonElement>('button')
  tabs?.[newIndex]?.focus()
}
</script>

<template>
  <div
    ref="tabsRef"
    class="framework-tabs"
    role="tablist"
    aria-label="Select framework"
  >
    <button
      v-for="(fw, index) in frameworks"
      :key="fw.id"
      role="tab"
      :id="`tab-${fw.id}`"
      :aria-selected="modelValue === fw.id"
      :aria-label="fw.label"
      :tabindex="modelValue === fw.id ? 0 : -1"
      :class="['tab', fw.id, { active: modelValue === fw.id }]"
      @click="select(fw.id)"
      @keydown="handleKeydown($event, index)"
    >
      <IconReact v-if="fw.id === 'react'" class="tab-icon" />
      <IconVue v-else-if="fw.id === 'vue'" class="tab-icon" />
      <IconSvelte v-else-if="fw.id === 'svelte'" class="tab-icon" />
      <span class="tab-label">{{ fw.file }}</span>
    </button>
  </div>
</template>

<style scoped>
.framework-tabs {
  display: flex;
  align-items: center;
  gap: 2px;
}

.tab {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.375rem;
  height: 32px;
  border: none;
  border-radius: 6px;
  background: transparent;
  color: var(--landing-text-muted, #52525b);
  cursor: pointer;
  font-size: 0.8125rem;
  font-weight: 500;
  font-family: inherit;
  letter-spacing: -0.01em;
  white-space: nowrap;
  overflow: hidden;
  padding: 0 0.5rem;
}

/* Inactive tabs - icon only with tinted colors */
.tab:not(.active) {
  transition:
    opacity 0.15s ease,
    background 0.15s ease;
}

.tab:not(.active):hover {
  background: var(--landing-code-tab-bg, rgba(0, 0, 0, 0.04));
}

.tab:not(.active) .tab-label {
  display: none;
}

/* Framework-specific colors for inactive state (tinted) */
.tab.react:not(.active) {
  color: rgba(97, 218, 251, 0.4);
}

.tab.react:not(.active):hover {
  color: rgba(97, 218, 251, 0.7);
}

.tab.vue:not(.active) {
  color: rgba(66, 184, 131, 0.4);
}

.tab.vue:not(.active):hover {
  color: rgba(66, 184, 131, 0.7);
}

.tab.svelte:not(.active) {
  color: rgba(255, 62, 0, 0.4);
}

.tab.svelte:not(.active):hover {
  color: rgba(255, 62, 0, 0.7);
}

/* Active tab - icon + filename */
.tab.active {
  background: var(--landing-code-tab-bg, rgba(0, 0, 0, 0.04));
  color: var(--landing-text-primary, #fafafa);
  padding: 0 0.75rem;
}

/* Framework-specific colors for active state */
.tab.active.react {
  color: #61dafb;
}

.tab.active.vue {
  color: #42b883;
}

.tab.active.svelte {
  color: #ff3e00;
}

.tab-icon {
  width: 16px;
  height: 16px;
  flex-shrink: 0;
}

.tab-label {
  color: var(--landing-text-secondary, #a1a1aa);
}

.tab:focus-visible {
  outline: 2px solid var(--landing-primary, #2563eb);
  outline-offset: 2px;
}
</style>
