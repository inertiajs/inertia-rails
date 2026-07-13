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
  align-items: flex-end;
  gap: 0;
}

/* Base tab styles */
.tab {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.375rem;
  height: 32px;
  border: none;
  background: transparent;
  color: var(--landing-text-muted);
  cursor: pointer;
  font-size: 0.75rem;
  font-weight: 500;
  font-family: inherit;
  letter-spacing: -0.01em;
  white-space: nowrap;
  padding: 0 0.625rem;
  transition: color 0.15s ease;
}

/* Inactive tabs - icon only */
.tab:not(.active) .tab-label {
  display: none;
}

/* Framework-specific colors for inactive state */
.tab.react:not(.active) {
  color: rgba(97, 218, 251, 0.4);
}

.tab.react:not(.active):hover {
  color: rgba(97, 218, 251, 0.8);
}

.tab.vue:not(.active) {
  color: rgba(66, 184, 131, 0.4);
}

.tab.vue:not(.active):hover {
  color: rgba(66, 184, 131, 0.8);
}

.tab.svelte:not(.active) {
  color: rgba(255, 62, 0, 0.4);
}

.tab.svelte:not(.active):hover {
  color: rgba(255, 62, 0, 0.8);
}

/* Active tab - VS Code connected style */
.tab.active {
  background: var(--landing-code-content);
  border: 1px solid var(--landing-code-border);
  border-bottom: none;
  border-radius: 6px 6px 0 0;
  padding: 0 0.75rem;
  position: relative;
}

/* Cover the border line below active tab */
.tab.active::after {
  content: '';
  position: absolute;
  bottom: -1px;
  left: 0;
  right: 0;
  height: 1px;
  background: var(--landing-code-content);
}

/* Framework-specific icon colors for active state */
.tab.active.react .tab-icon {
  color: #61dafb;
}

.tab.active.vue .tab-icon {
  color: #42b883;
}

.tab.active.svelte .tab-icon {
  color: #ff3e00;
}

.tab-icon {
  width: 14px;
  height: 14px;
  flex-shrink: 0;
}

.tab-label {
  color: var(--landing-text-secondary);
}

.tab:focus-visible {
  outline: 2px solid var(--landing-primary);
  outline-offset: 2px;
}

/* Mobile adjustments */
@media (max-width: 960px) {
  .framework-tabs {
    align-items: center;
  }

  .tab.active {
    border: 1px solid var(--landing-code-border);
    border-radius: 6px;
  }

  .tab.active::after {
    display: none;
  }
}
</style>
