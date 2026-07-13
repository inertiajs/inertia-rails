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
/* Ghost button - subtle, appears on hover */
.copy-button {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.375rem;
  border: none;
  border-radius: 4px;
  background: transparent;
  color: var(--landing-text-muted, #71717a);
  cursor: pointer;
  font-size: 0.75rem;
  font-family: inherit;
  opacity: 0.4;
  transition: all 0.15s ease;
}

.copy-button:hover {
  opacity: 1;
  color: var(--landing-text-secondary, #a1a1aa);
  background: var(--landing-code-tab-bg, rgba(0, 0, 0, 0.04));
}

.copy-button:active {
  opacity: 0.8;
}

.copy-button:focus-visible {
  opacity: 1;
  outline: 2px solid var(--landing-primary, #3b82f6);
  outline-offset: 2px;
}

.copy-button.copied {
  opacity: 1;
  color: #4ade80;
}

.copy-button.icon-only {
  padding: 0.375rem;
}

.icon {
  width: 0.75rem;
  height: 0.75rem;
  flex-shrink: 0;
}

.label {
  font-weight: 600;
  letter-spacing: -0.01em;
}

@media (prefers-reduced-motion: reduce) {
  .copy-button {
    transition: none;
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
