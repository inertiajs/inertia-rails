<script setup lang="ts">
import { ref } from 'vue'
import { starterKits } from '../../../data/starter-kits'
import {
  IconPackage,
  IconPlus,
  IconReact,
  IconSvelte,
  IconVue,
} from '../../icons'
import CopyButton from '../CopyButton.vue'

// Mobile get started choice
const activeSetupChoice = ref<'quick' | 'kit' | null>('quick')

const selectSetupChoice = (choice: 'quick' | 'kit') => {
  activeSetupChoice.value = activeSetupChoice.value === choice ? null : choice
}
</script>

<template>
  <section class="getting-started">
    <div class="section-header">
      <h2>Get&nbsp;started</h2>
      <p>
        Add to your existing Rails&nbsp;app or jump&nbsp;in with
        a&nbsp;ready-to-use starter&nbsp;kit.
      </p>
    </div>

    <div class="setup-options">
      <!-- Option 1: Add to existing app -->
      <div class="setup-option">
        <div class="option-header">
          <span class="option-icon" aria-hidden="true">
            <IconPlus />
          </span>
          <h3>Add to existing&nbsp;app</h3>
        </div>
        <div class="install-steps">
          <div class="install-step">
            <span class="install-num">1</span>
            <div class="install-code">
              <code>bundle add inertia_rails</code>
              <CopyButton code="bundle add inertia_rails" icon-only />
            </div>
          </div>
          <div class="install-step">
            <span class="install-num">2</span>
            <div class="install-code">
              <code>bin/rails g inertia:install</code>
              <CopyButton code="bin/rails g inertia:install" icon-only />
            </div>
          </div>
        </div>
        <p class="option-note">
          Configures Vite, your chosen framework, and creates
          example&nbsp;pages.
        </p>
      </div>

      <!-- Divider -->
      <div class="setup-divider" aria-hidden="true">
        <span>or</span>
      </div>

      <!-- Option 2: Use a starter kit -->
      <div class="setup-option starter-kits-option">
        <div class="option-header">
          <span class="option-icon" aria-hidden="true">
            <IconPackage />
          </span>
          <h3>Start with a&nbsp;kit</h3>
        </div>
        <div class="kits-row">
          <a
            v-for="kit in starterKits"
            :key="kit.framework"
            :href="kit.url"
            target="_blank"
            rel="noopener"
            class="kit-pill"
            :class="kit.framework"
          >
            <IconReact v-if="kit.framework === 'react'" class="kit-pill-icon" />
            <IconVue
              v-else-if="kit.framework === 'vue'"
              class="kit-pill-icon"
            />
            <IconSvelte v-else class="kit-pill-icon" />
            <span class="kit-pill-name">{{
              kit.name.replace(' Starter Kit', '')
            }}</span>
            <span class="kit-pill-arrow" aria-hidden="true">→</span>
          </a>
        </div>
        <p class="option-note">
          Authentication, Vite, optional SSR, and Kamal
          deployment&nbsp;included.
        </p>
      </div>
    </div>

    <!-- Mobile Interactive Choice -->
    <div class="mobile-setup-choice">
      <button
        class="choice-card"
        :class="{ active: activeSetupChoice === 'quick' }"
        @click="selectSetupChoice('quick')"
      >
        <span class="choice-icon" aria-hidden="true">
          <IconPlus />
        </span>
        <span class="choice-label">Quick&nbsp;Start</span>
      </button>
      <button
        class="choice-card"
        :class="{ active: activeSetupChoice === 'kit' }"
        @click="selectSetupChoice('kit')"
      >
        <span class="choice-icon" aria-hidden="true">
          <IconPackage />
        </span>
        <span class="choice-label">Starter&nbsp;Kit</span>
      </button>
    </div>

    <!-- Quick Start Expanded -->
    <div
      class="choice-content"
      :class="{ visible: activeSetupChoice === 'quick' }"
    >
      <div class="mobile-install-steps">
        <div class="mobile-install-step">
          <code>bundle add inertia_rails</code>
          <CopyButton code="bundle add inertia_rails" icon-only />
        </div>
        <div class="mobile-install-step">
          <code>bin/rails g inertia:install</code>
          <CopyButton code="bin/rails g inertia:install" icon-only />
        </div>
      </div>
    </div>

    <!-- Starter Kits Expanded -->
    <div
      class="choice-content"
      :class="{ visible: activeSetupChoice === 'kit' }"
    >
      <div class="mobile-kits-grid">
        <a
          v-for="kit in starterKits"
          :key="kit.framework"
          :href="kit.url"
          target="_blank"
          rel="noopener"
          class="mobile-kit-card"
          :class="kit.framework"
        >
          <IconReact v-if="kit.framework === 'react'" class="mobile-kit-icon" />
          <IconVue
            v-else-if="kit.framework === 'vue'"
            class="mobile-kit-icon"
          />
          <IconSvelte v-else class="mobile-kit-icon" />
          <span class="mobile-kit-name">{{
            kit.name.replace(' Starter Kit', '')
          }}</span>
          <span class="mobile-kit-arrow" aria-hidden="true">→</span>
        </a>
      </div>
    </div>
  </section>
</template>

<style scoped>
.getting-started {
  padding: 6rem 1.5rem;
  max-width: var(--landing-max-width);
  margin: 0 auto;
  position: relative;
  z-index: 1;
  padding-top: 4rem;
  padding-bottom: 4rem;
}

.section-header {
  text-align: center;
  margin-bottom: 4rem;
}

.section-header h2 {
  font-size: clamp(2rem, 4vw, 2.75rem);
  font-weight: 800;
  margin-bottom: 1rem;
  letter-spacing: -0.03em;
  padding-bottom: 0.1em;
  text-wrap: balance;
}

.section-header p {
  color: var(--landing-text-secondary);
  font-size: 1.125rem;
  max-width: 540px;
  margin: 0 auto;
  line-height: 1.7;
}

.setup-options {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  gap: 2rem;
  align-items: start;
  max-width: 960px;
  margin: 0 auto;
}

.setup-option {
  padding: 1.75rem;
  background: var(--landing-card-bg);
  border: 1px solid var(--landing-border);
  border-radius: 1rem;
  backdrop-filter: blur(12px);
}

.option-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1.25rem;
}

.option-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 2.25rem;
  height: 2.25rem;
  padding: 0.5rem;
  background: var(--landing-primary-subtle);
  border-radius: 0.5rem;
  color: var(--landing-primary);
}

.option-icon svg {
  width: 100%;
  height: 100%;
}

.option-header h3 {
  font-size: 1rem;
  font-weight: 700;
  letter-spacing: -0.02em;
  margin: 0;
}

.install-steps {
  display: flex;
  flex-direction: column;
  gap: 0.625rem;
  margin-bottom: 1rem;
}

.install-step {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.install-num {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 1.375rem;
  height: 1.375rem;
  background: var(--landing-primary);
  color: white;
  font-size: 0.6875rem;
  font-weight: 700;
  border-radius: 50%;
  flex-shrink: 0;
}

.install-code {
  position: relative;
  display: flex;
  align-items: center;
  flex: 1;
  padding: 0.4375rem 0.625rem;
  padding-right: 2.25rem;
  background: var(--landing-surface);
  border: 1px solid var(--landing-border);
  border-radius: 0.375rem;
  transition: border-color 0.2s ease;
}

.install-code:hover {
  border-color: var(--landing-primary);
}

.install-code code {
  font-family:
    ui-monospace, 'Cascadia Code', 'Source Code Pro', Menlo, Monaco, Consolas,
    monospace;
  font-size: 0.75rem;
  color: var(--landing-text-primary);
  font-weight: 500;
  white-space: nowrap;
}

.install-code :deep(.copy-button) {
  position: absolute;
  top: 50%;
  right: 0.25rem;
  transform: translateY(-50%);
}

.option-note {
  font-size: 0.8125rem;
  color: var(--landing-text-secondary);
  line-height: 1.5;
  margin: 0;
}

/* Divider */
.setup-divider {
  display: flex;
  align-items: center;
  justify-content: center;
  padding-top: 3rem;
}

.setup-divider span {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 2.5rem;
  height: 2.5rem;
  background: var(--landing-surface);
  border: 1px solid var(--landing-border);
  border-radius: 50%;
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--landing-text-muted);
  text-transform: lowercase;
}

/* Starter Kits Pills */
.kits-row {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.kit-pill {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  padding: 0.625rem 0.875rem;
  background: var(--landing-surface);
  border: 1px solid var(--landing-border);
  border-radius: 0.5rem;
  text-decoration: none;
  color: inherit;
  transition: all 0.25s var(--ease-out-expo);
}

.kit-pill:hover {
  border-color: var(--landing-primary);
  background: var(--landing-primary-subtle);
}

.kit-pill:focus-visible {
  outline: 2px solid var(--landing-primary);
  outline-offset: 2px;
}

.kit-pill-icon {
  width: 1.125rem;
  height: 1.125rem;
  flex-shrink: 0;
}

.kit-pill.react .kit-pill-icon {
  color: #61dafb;
}
.kit-pill.vue .kit-pill-icon {
  color: #42b883;
}
.kit-pill.svelte .kit-pill-icon {
  color: #ff3e00;
}

.kit-pill-name {
  font-size: 0.8125rem;
  font-weight: 600;
  flex: 1;
}

.kit-pill-arrow {
  font-size: 0.875rem;
  color: var(--landing-text-muted);
  transition:
    transform 0.2s ease,
    color 0.2s ease;
}

.kit-pill:hover .kit-pill-arrow {
  transform: translateX(2px);
  color: var(--landing-primary);
}

/* Mobile Setup Choice - Hidden on desktop */
.mobile-setup-choice,
.choice-content {
  display: none;
}

@media (max-width: 960px) {
  .setup-options {
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  .setup-divider {
    padding: 1rem 0;
  }
}

@media (max-width: 640px) {
  .getting-started {
    padding: 2rem 1rem;
  }

  .section-header {
    margin-bottom: 2rem;
  }

  .section-header h2 {
    font-size: 1.75rem;
  }

  .setup-option {
    padding: 1.25rem;
  }

  .install-code code {
    font-size: 0.6875rem;
  }

  /* Hide desktop setup options on mobile */
  .setup-options {
    display: none;
  }

  /* Mobile Interactive Setup Choice */
  .mobile-setup-choice {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.75rem;
    max-width: 400px;
    margin: 0 auto;
  }

  .choice-card {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.75rem;
    padding: 1.25rem 1rem;
    background: var(--landing-card-bg);
    border: 1px solid var(--landing-border);
    border-radius: 1rem;
    cursor: pointer;
    transition: all 0.3s var(--ease-out-expo);
    -webkit-tap-highlight-color: transparent;
  }

  .choice-card:active {
    transform: scale(0.98);
  }

  .choice-card.active {
    border-color: var(--landing-primary);
    background: var(--landing-primary-subtle);
  }

  .choice-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 48px;
    height: 48px;
    background: var(--landing-primary-subtle);
    border-radius: 0.75rem;
    color: var(--landing-primary);
    transition: all 0.3s var(--ease-out-expo);
  }

  .choice-card.active .choice-icon {
    background: var(--landing-primary);
    color: white;
    transform: scale(1.1);
  }

  .choice-icon svg {
    width: 24px;
    height: 24px;
  }

  .choice-label {
    font-size: 0.875rem;
    font-weight: 600;
    color: var(--landing-text-primary);
  }

  .choice-content {
    display: grid;
    grid-template-rows: 0fr;
    transition: grid-template-rows 0.3s var(--ease-out-expo);
    overflow: hidden;
  }

  .choice-content.visible {
    display: grid;
    grid-template-rows: 1fr;
    margin-top: 1rem;
  }

  .choice-content > * {
    overflow: hidden;
  }

  .mobile-install-steps {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .mobile-install-step {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 0.5rem;
    padding: 0.75rem 1rem;
    background: var(--landing-code-bg);
    border: 1px solid var(--landing-border);
    border-radius: 0.5rem;
  }

  .mobile-install-step code {
    font-size: 0.75rem;
    color: var(--landing-text-secondary);
    font-family: 'JetBrains Mono', ui-monospace, monospace;
  }

  .mobile-kits-grid {
    display: grid;
    grid-template-columns: 1fr;
    gap: 0.5rem;
  }

  .mobile-kit-card {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.875rem 1rem;
    background: var(--landing-card-bg);
    border: 1px solid var(--landing-border);
    border-radius: 0.75rem;
    text-decoration: none;
    color: inherit;
    transition: all 0.2s ease;
  }

  .mobile-kit-card:active {
    transform: scale(0.98);
  }

  .mobile-kit-card.react {
    border-color: rgba(97, 218, 251, 0.3);
  }
  .mobile-kit-card.vue {
    border-color: rgba(66, 184, 131, 0.3);
  }
  .mobile-kit-card.svelte {
    border-color: rgba(255, 62, 0, 0.3);
  }

  .mobile-kit-icon {
    width: 24px;
    height: 24px;
    flex-shrink: 0;
  }

  .mobile-kit-card.react .mobile-kit-icon {
    color: #61dafb;
  }
  .mobile-kit-card.vue .mobile-kit-icon {
    color: #42b883;
  }
  .mobile-kit-card.svelte .mobile-kit-icon {
    color: #ff3e00;
  }

  .mobile-kit-name {
    font-size: 0.875rem;
    font-weight: 500;
    color: var(--landing-text-primary);
    flex: 1;
  }

  .mobile-kit-arrow {
    color: var(--landing-text-muted);
    font-size: 1rem;
    transition: transform 0.2s ease;
  }

  .mobile-kit-card:active .mobile-kit-arrow {
    transform: translateX(2px);
  }
}
</style>
