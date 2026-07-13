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
  <div class="split-editor">
    <!-- Tab Bar - VS Code style, tabs connect to panes -->
    <div class="editor-tabs">
      <div class="tabs-group left">
        <span class="file-tab">
          <IconRails class="tab-icon" />
          <span class="tab-label">users_controller.rb</span>
        </span>
        <CopyButton :code="railsCode" :icon-only="true" />
      </div>
      <div class="tabs-group right">
        <FrameworkToggle
          :model-value="selectedFramework"
          @update:model-value="updateFramework"
        />
        <CopyButton :code="frontendCode[selectedFramework]" :icon-only="true" />
      </div>
    </div>

    <!-- Split Panes -->
    <div class="editor-panes">
      <div class="code-pane">
        <div
          class="code-content"
          v-html="railsCodeHtml || `<pre><code>${railsCode}</code></pre>`"
        />
      </div>
      <div class="pane-divider" aria-hidden="true"></div>
      <div class="code-pane">
        <div
          class="code-content"
          v-html="
            frontendCodeHtml[selectedFramework] ||
            `<pre><code>${frontendCode[selectedFramework]}</code></pre>`
          "
        />
      </div>
    </div>

    <!-- Mobile Layout: Tab + Code paired together -->
    <div class="mobile-code-panels">
      <div class="mobile-panel">
        <div class="mobile-panel-header">
          <span class="file-tab">
            <IconRails class="tab-icon" />
            <span class="tab-label">users_controller.rb</span>
          </span>
          <CopyButton :code="railsCode" :icon-only="true" />
        </div>
        <div class="code-pane">
          <div
            class="code-content"
            v-html="railsCodeHtml || `<pre><code>${railsCode}</code></pre>`"
          />
        </div>
      </div>
      <div class="mobile-panel">
        <div class="mobile-panel-header">
          <FrameworkToggle
            :model-value="selectedFramework"
            @update:model-value="updateFramework"
          />
          <CopyButton
            :code="frontendCode[selectedFramework]"
            :icon-only="true"
          />
        </div>
        <div class="code-pane">
          <div
            class="code-content"
            v-html="
              frontendCodeHtml[selectedFramework] ||
              `<pre><code>${frontendCode[selectedFramework]}</code></pre>`
            "
          />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.split-editor {
  width: 100%;
  max-width: var(--landing-max-width);
  margin: 0 auto;
  border-radius: 0.75rem;
  overflow: hidden;
  background: var(--landing-code-content);
  border: 1px solid var(--landing-code-border);
  box-shadow: var(--landing-code-shadow);
  transition:
    border-color 0.2s ease,
    box-shadow 0.2s ease;
}

.split-editor:hover {
  border-color: var(--landing-primary);
  box-shadow: var(--landing-code-shadow-hover);
}

/* Tab Bar - VS Code style with connected tabs */
.editor-tabs {
  display: grid;
  grid-template-columns: 1fr 1fr;
  background: var(--landing-code-header);
}

.tabs-group {
  display: flex;
  align-items: flex-end;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem 0;
}

.tabs-group :deep(.copy-button) {
  margin-left: auto;
  align-self: center;
}

.tabs-group.left {
  border-right: 1px solid var(--landing-code-border);
}

/* Tab connects to content below - no bottom border, same bg as pane */
.file-tab {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  height: 32px;
  padding: 0 0.75rem;
  background: var(--landing-code-content);
  border: 1px solid var(--landing-code-border);
  border-bottom: none;
  border-radius: 6px 6px 0 0;
  font-size: 0.75rem;
  font-weight: 500;
  color: var(--landing-text-secondary);
  position: relative;
}

/* Extend tab background to cover the border line */
.file-tab::after {
  content: '';
  position: absolute;
  bottom: -1px;
  left: 0;
  right: 0;
  height: 1px;
  background: var(--landing-code-content);
}

.file-tab .tab-icon {
  width: 14px;
  height: 14px;
  flex-shrink: 0;
  color: #cc0000;
}

.file-tab .tab-label {
  letter-spacing: -0.01em;
}

/* Split Panes */
.editor-panes {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  min-height: 240px;
  background: var(--landing-code-content);
  border-top: 1px solid var(--landing-code-border);
}

.code-pane {
  overflow-x: auto;
}

.pane-divider {
  width: 1px;
  background: var(--landing-code-border);
}

.code-content {
  text-align: left;
  height: 100%;
}

.code-content :deep(pre) {
  margin: 0;
  padding: 1rem 1.25rem;
  font-size: 0.8125rem;
  line-height: 1.7;
  background: transparent !important;
  overflow-x: auto;
  height: 100%;
}

.code-content :deep(code) {
  font-family:
    'JetBrains Mono', ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Monaco,
    Consolas, monospace;
  white-space: pre;
  font-feature-settings:
    'liga' 1,
    'calt' 1;
}

.code-content :deep(.shiki) {
  background: transparent !important;
}

/* Mobile panels - hidden by default */
.mobile-code-panels {
  display: none;
}

/* Mobile: Use paired tab+code layout */
@media (max-width: 960px) {
  .split-editor {
    border: none;
    background: transparent;
    box-shadow: none;
  }

  .split-editor:hover {
    border-color: transparent;
    box-shadow: none;
  }

  /* Hide desktop layout */
  .editor-tabs,
  .editor-panes {
    display: none;
  }

  /* Show mobile layout - stacked windows */
  .mobile-code-panels {
    display: flex;
    flex-direction: column;
    position: relative;
  }

  .mobile-panel {
    border: 1px solid var(--landing-code-border);
    border-radius: 0.75rem;
    overflow: hidden;
    background: var(--landing-code-content);
    position: relative;
  }

  /* First panel: peeks out behind */
  .mobile-panel:first-child {
    z-index: 1;
    padding-bottom: 0.75rem;
  }

  /* Second panel: sits on top with shadow */
  .mobile-panel:last-child {
    z-index: 2;
    box-shadow:
      0 -4px 12px -2px rgba(0, 0, 0, 0.08),
      0 -2px 4px -1px rgba(0, 0, 0, 0.04);
    margin-top: -0.75rem;
  }

  .mobile-panel-header {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 0.75rem;
    background: var(--landing-code-header);
  }

  .mobile-panel-header :deep(.copy-button) {
    margin-left: auto;
  }

  .mobile-panel .file-tab {
    border-radius: 6px;
  }

  .mobile-panel .file-tab::after {
    display: none;
  }

  .mobile-panel .code-pane {
    background: var(--landing-code-content);
  }
}

:root.dark .mobile-panel:last-child {
  box-shadow:
    0 -4px 16px -2px rgba(0, 0, 0, 0.4),
    0 -2px 6px -1px rgba(0, 0, 0, 0.2);
}

@media (max-width: 640px) {
  .mobile-panel-header {
    padding: 0.375rem 0.5rem;
  }

  .code-content :deep(pre) {
    font-size: 0.75rem;
    padding: 0.75rem;
    line-height: 1.6;
  }
}
</style>
