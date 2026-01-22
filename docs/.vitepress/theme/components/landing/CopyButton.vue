<script setup lang="ts">
import { onUnmounted, ref } from 'vue'
import { IconCheck, IconCopy } from '../icons'

const props = defineProps<{
  code: string
  iconOnly?: boolean
}>()

const copied = ref(false)
const announcement = ref('')
let timeoutId: ReturnType<typeof setTimeout> | null = null

const copyCode = async () => {
  // Cancel any pending timeout to prevent race conditions
  if (timeoutId) {
    clearTimeout(timeoutId)
    timeoutId = null
  }

  try {
    await navigator.clipboard.writeText(props.code)
    copied.value = true
    announcement.value = 'Code copied to clipboard'

    timeoutId = setTimeout(() => {
      copied.value = false
      announcement.value = ''
      timeoutId = null
    }, 2000)
  } catch {
    announcement.value = 'Failed to copy code'
    // Reset error message after delay
    timeoutId = setTimeout(() => {
      announcement.value = ''
      timeoutId = null
    }, 2000)
  }
}

onUnmounted(() => {
  if (timeoutId) {
    clearTimeout(timeoutId)
  }
})
</script>

<template>
  <button
    type="button"
    class="copy-button"
    :class="{ copied, 'icon-only': iconOnly }"
    :aria-label="copied ? 'Copied to clipboard' : 'Copy code to clipboard'"
    @click="copyCode"
  >
    <IconCheck v-if="copied" class="icon" />
    <IconCopy v-else class="icon" />
    <span v-if="!iconOnly" class="label">{{
      copied ? 'Copied!' : 'Copy'
    }}</span>
  </button>

  <!-- ARIA live region for screen reader announcements -->
  <div aria-live="polite" aria-atomic="true" class="sr-only">
    {{ announcement }}
  </div>
</template>

<style scoped>
.copy-button {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.375rem 0.625rem;
  border: 1px solid var(--landing-code-border, rgba(0, 0, 0, 0.08));
  border-radius: 6px;
  background: var(--landing-code-tab-bg, rgba(0, 0, 0, 0.04));
  color: var(--landing-text-muted, #71717a);
  cursor: pointer;
  font-size: 0.75rem;
  font-family: inherit;
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

.copy-button:hover {
  color: var(--landing-text-primary, #fafafa);
  border-color: var(--landing-border, rgba(0, 0, 0, 0.1));
  background: var(--landing-surface, rgba(0, 0, 0, 0.06));
  transform: scale(1.05);
}

.copy-button:active {
  transform: scale(0.95);
}

.copy-button:focus-visible {
  outline: 2px solid var(--landing-primary, #3b82f6);
  outline-offset: 2px;
}

.copy-button.copied {
  color: #4ade80;
  border-color: rgba(74, 222, 128, 0.3);
  background: rgba(74, 222, 128, 0.1);
  animation: copySuccess 0.3s ease;
}

@keyframes copySuccess {
  0% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.1);
  }
  100% {
    transform: scale(1);
  }
}

.copy-button.icon-only {
  padding: 0.5rem;
  border-radius: 8px;
}

.icon {
  width: 0.875rem;
  height: 0.875rem;
  flex-shrink: 0;
  transition: transform 0.2s ease;
}

.copy-button.copied .icon {
  animation: checkPop 0.3s ease;
}

@keyframes checkPop {
  0% {
    transform: scale(0.5);
    opacity: 0;
  }
  50% {
    transform: scale(1.2);
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

.label {
  font-weight: 600;
  letter-spacing: -0.01em;
}

@media (prefers-reduced-motion: reduce) {
  .copy-button:hover {
    transform: none;
  }

  .copy-button:active {
    transform: none;
  }

  .copy-button.copied,
  .copy-button.copied .icon {
    animation: none;
  }
}

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
</style>
