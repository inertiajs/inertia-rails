<script setup lang="ts">
import { codeToHtml } from 'shiki'
import { useData } from 'vitepress'
import { onMounted, ref, watch } from 'vue'
import {
  frontendCode,
  railsCode,
  type Framework,
} from '../../data/code-examples'
import { IconRails } from '../icons'
import CopyButton from './CopyButton.vue'
import FrameworkToggle from './FrameworkToggle.vue'

const { isDark } = useData()

// Highlighted code HTML
const railsCodeHtml = ref('')
const frontendCodeHtml = ref<Record<string, string>>({
  react: '',
  vue: '',
  svelte: '',
})

const selectedFramework = ref<Framework>('react')

// Highlight code function
const highlightCode = async () => {
  const theme = isDark.value ? 'github-dark' : 'github-light'

  railsCodeHtml.value = await codeToHtml(railsCode, {
    lang: 'ruby',
    theme,
  })

  frontendCodeHtml.value = {
    react: await codeToHtml(frontendCode.react, { lang: 'tsx', theme }),
    vue: await codeToHtml(frontendCode.vue, { lang: 'vue', theme }),
    svelte: await codeToHtml(frontendCode.svelte, { lang: 'svelte', theme }),
  }
}

// Re-highlight when theme changes
watch(isDark, highlightCode)

// Initialize from localStorage on mount (SSR-safe)
onMounted(async () => {
  const stored = localStorage.getItem('vitepress:tabsSharedState')
  if (stored) {
    try {
      const parsed = JSON.parse(stored)
      const fw = parsed.frameworks?.toLowerCase()
      if (fw === 'react' || fw === 'vue' || fw === 'svelte') {
        selectedFramework.value = fw
      }
    } catch {}
  }

  // Highlight code
  await highlightCode()
})

// Sync selection back to localStorage
const updateFramework = (fw: Framework) => {
  selectedFramework.value = fw
  const stored = localStorage.getItem('vitepress:tabsSharedState')
  let state: Record<string, unknown> = {}
  if (stored) {
    try {
      state = JSON.parse(stored)
    } catch {
      // Ignore malformed JSON, start fresh
    }
  }
  // Match the case used by vitepress-plugin-tabs (capitalized)
  state.frameworks = fw.charAt(0).toUpperCase() + fw.slice(1)
  localStorage.setItem('vitepress:tabsSharedState', JSON.stringify(state))
}
</script>

<template>
  <div class="hero-code-panels">
    <div class="code-panel">
      <div class="panel-header">
        <div class="panel-header-left">
          <div class="window-controls" aria-hidden="true">
            <span class="window-dot dot-close"></span>
            <span class="window-dot dot-minimize"></span>
            <span class="window-dot dot-maximize"></span>
          </div>
          <span class="panel-tab">
            <IconRails class="tab-icon" />
            <span class="tab-label">users_controller.rb</span>
          </span>
        </div>
        <CopyButton :code="railsCode" :icon-only="true" />
      </div>
      <div
        class="code-content"
        v-html="railsCodeHtml || `<pre><code>${railsCode}</code></pre>`"
      />
    </div>
    <div class="code-connector" aria-hidden="true">
      <div class="connector-glow"></div>
      <svg
        width="32"
        height="32"
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M5 12H19M19 12L12 5M19 12L12 19"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>
    </div>
    <div class="code-panel">
      <div class="panel-header">
        <div class="panel-header-left">
          <div class="window-controls" aria-hidden="true">
            <span class="window-dot dot-close"></span>
            <span class="window-dot dot-minimize"></span>
            <span class="window-dot dot-maximize"></span>
          </div>
          <FrameworkToggle
            :model-value="selectedFramework"
            @update:model-value="updateFramework"
          />
        </div>
        <CopyButton :code="frontendCode[selectedFramework]" :icon-only="true" />
      </div>
      <div
        class="code-content"
        v-html="
          frontendCodeHtml[selectedFramework] ||
          `<pre><code>${frontendCode[selectedFramework]}</code></pre>`
        "
      />
    </div>
  </div>
</template>

<style scoped>
.hero-code-panels {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  gap: 1.5rem;
  align-items: start;
  width: 100%;
  max-width: var(--landing-max-width);
  margin: 0 auto;
  padding: 0 1.5rem;
}

.hero-code-panels .code-panel {
  background: var(--landing-code-bg);
  border: 1px solid var(--landing-code-border);
  border-radius: 1rem;
  overflow: hidden;
  backdrop-filter: blur(16px);
  transition:
    border-color 0.2s ease,
    background 0.2s ease,
    box-shadow 0.2s ease;
  box-shadow: var(--landing-code-shadow);
}

.hero-code-panels .code-panel:hover {
  background: var(--landing-code-bg-hover);
  border-color: var(--landing-primary);
  box-shadow: var(--landing-code-shadow-hover);
}

/* Panel Header - Window Chrome */
.hero-code-panels .panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.75rem 1rem;
  background: var(--landing-code-header);
  border-bottom: 1px solid var(--landing-code-border);
  min-height: 44px;
}

.hero-code-panels .panel-header-left {
  display: flex;
  align-items: center;
  gap: 1rem;
}

/* Traffic Light Dots */
.window-controls {
  display: flex;
  align-items: center;
  gap: 6px;
}

.window-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  transition: opacity 0.2s ease;
}

.window-dot.dot-close {
  background: linear-gradient(180deg, #ff6058 0%, #e04b43 100%);
  box-shadow: inset 0 -1px 1px rgba(0, 0, 0, 0.2);
}

.window-dot.dot-minimize {
  background: linear-gradient(180deg, #ffbd2e 0%, #dea123 100%);
  box-shadow: inset 0 -1px 1px rgba(0, 0, 0, 0.2);
}

.window-dot.dot-maximize {
  background: linear-gradient(180deg, #27ca40 0%, #1aab29 100%);
  box-shadow: inset 0 -1px 1px rgba(0, 0, 0, 0.2);
}

.code-panel:not(:hover) .window-dot {
  opacity: 0.5;
}

/* Panel Tab - Safari-style file tab */
.hero-code-panels .panel-tab {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  height: 32px;
  padding: 0 0.75rem;
  background: var(--landing-code-tab-bg);
  border-radius: 6px;
  color: #cc0000;
}

.hero-code-panels .panel-tab .tab-icon {
  width: 16px;
  height: 16px;
  flex-shrink: 0;
}

.hero-code-panels .panel-tab .tab-label {
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--landing-text-secondary);
  letter-spacing: -0.01em;
}

/* Code Content Area */
.hero-code-panels .code-content {
  text-align: left;
  overflow-x: auto;
  max-height: 280px;
  background: var(--landing-code-content);
}

.hero-code-panels .code-content :deep(pre) {
  margin: 0;
  padding: 1.25rem 1.5rem;
  font-size: 0.8125rem;
  line-height: 1.7;
  background: transparent !important;
  overflow-x: auto;
}

.hero-code-panels .code-content :deep(code) {
  font-family:
    'JetBrains Mono', ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Monaco,
    Consolas, monospace;
  white-space: pre;
  font-feature-settings:
    'liga' 1,
    'calt' 1;
}

.hero-code-panels .code-content :deep(.shiki) {
  background: transparent !important;
}

/* Arrow Connector - Enhanced */
.hero-code-panels .code-connector {
  display: flex;
  align-items: center;
  justify-content: center;
  padding-top: 2.75rem;
  color: var(--landing-primary);
  position: relative;
}

.hero-code-panels .code-connector svg {
  position: relative;
  z-index: 1;
  filter: drop-shadow(0 2px 4px hsl(var(--landing-shadow-color) / 0.2));
  animation: connectorPulse 2s ease-in-out infinite;
}

.connector-glow {
  position: absolute;
  width: 48px;
  height: 48px;
  background: radial-gradient(
    circle,
    var(--landing-primary-subtle) 0%,
    transparent 70%
  );
  border-radius: 50%;
  animation: connectorGlow 2s ease-in-out infinite;
}

@keyframes connectorPulse {
  0%,
  100% {
    opacity: 0.8;
    transform: scale(1);
  }
  50% {
    opacity: 1;
    transform: scale(1.05);
  }
}

@keyframes connectorGlow {
  0%,
  100% {
    opacity: 0.5;
    transform: scale(1);
  }
  50% {
    opacity: 0.8;
    transform: scale(1.2);
  }
}

@media (max-width: 960px) {
  .hero-code-panels {
    grid-template-columns: 1fr;
    gap: 0.75rem;
  }

  .hero-code-panels .code-connector {
    transform: rotate(90deg);
    padding: 0.5rem 0;
    margin: -0.25rem 0;
  }

  .hero-code-panels .code-connector .connector-glow {
    display: none;
  }

  .hero-code-panels .code-content {
    max-height: none;
  }

  .hero-code-panels .panel-header {
    padding: 0.625rem 0.875rem;
  }

  .window-controls {
    display: none;
  }

  .hero-code-panels .panel-header-left {
    gap: 0.5rem;
  }
}

@media (max-width: 640px) {
  .hero-code-panels {
    padding: 0;
    gap: 0.75rem;
  }

  .hero-code-panels .code-content {
    max-height: none;
  }

  .hero-code-panels .code-content :deep(pre) {
    font-size: 0.8125rem;
    padding: 0.875rem 0.75rem;
    line-height: 1.6;
  }

  .hero-code-panels .panel-header {
    padding: 0.5rem 0.75rem;
  }

  .hero-code-panels .panel-title {
    font-size: 0.75rem;
  }

  .hero-code-panels .code-panel {
    border-radius: 0.75rem;
  }

  .hero-code-panels .code-connector {
    padding: 0.25rem 0;
    margin: -0.125rem 0;
  }
}

@media (prefers-reduced-motion: reduce) {
  .hero-code-panels .code-connector svg,
  .connector-glow {
    animation: none;
  }
}
</style>
