<script setup lang="ts">
import { onUnmounted, ref } from 'vue'
import {
  IconInertia,
  IconRails,
  IconReact,
  IconSvelte,
  IconVue,
} from '../icons'

const mobileFlowRef = ref<HTMLElement | null>(null)
const isFlowAnimating = ref(false)
const activeFramework = ref<string | null>(null)

// Track timeout IDs for cleanup
const flowTimeoutIds: ReturnType<typeof setTimeout>[] = []

const triggerFlowBurst = () => {
  isFlowAnimating.value = true
  activeFramework.value = null
  const timeoutId = setTimeout(() => {
    isFlowAnimating.value = false
  }, 1500)
  flowTimeoutIds.push(timeoutId)
}

const highlightFramework = (framework: string) => {
  activeFramework.value = activeFramework.value === framework ? null : framework
  isFlowAnimating.value = true
  const timeoutId = setTimeout(() => {
    isFlowAnimating.value = false
  }, 1200)
  flowTimeoutIds.push(timeoutId)
}

// Cleanup timeouts on unmount
onUnmounted(() => {
  flowTimeoutIds.forEach((id) => clearTimeout(id))
})

defineExpose({
  mobileFlowRef,
  isFlowAnimating,
  activeFramework,
  triggerFlowBurst,
  highlightFramework,
})
</script>

<template>
  <div
    ref="mobileFlowRef"
    class="mobile-flow-visual"
    :class="{
      animating: isFlowAnimating,
      [`active-${activeFramework}`]: activeFramework,
    }"
  >
    <button
      class="flow-node rails-node"
      aria-label="Rails"
      @click="triggerFlowBurst"
    >
      <IconRails />
    </button>
    <div class="flow-arrow flow-arrow-in">
      <span class="flow-particle"></span>
    </div>
    <button
      class="flow-node inertia-node"
      aria-label="Inertia - tap for animation"
      @click="triggerFlowBurst"
    >
      <IconInertia />
    </button>
    <div class="flow-arrow flow-arrow-out">
      <span class="flow-line top"><span class="flow-particle"></span></span>
      <span class="flow-line middle"><span class="flow-particle"></span></span>
      <span class="flow-line bottom"><span class="flow-particle"></span></span>
    </div>
    <div class="flow-frameworks">
      <button
        class="flow-node react-node"
        :class="{ active: activeFramework === 'react' }"
        aria-label="React"
        @click="highlightFramework('react')"
      >
        <IconReact />
      </button>
      <button
        class="flow-node vue-node"
        :class="{ active: activeFramework === 'vue' }"
        aria-label="Vue"
        @click="highlightFramework('vue')"
      >
        <IconVue />
      </button>
      <button
        class="flow-node svelte-node"
        :class="{ active: activeFramework === 'svelte' }"
        aria-label="Svelte"
        @click="highlightFramework('svelte')"
      >
        <IconSvelte />
      </button>
    </div>
  </div>
</template>

<style scoped>
/* Mobile Flow Visual - Hidden on desktop */
.mobile-flow-visual {
  display: none;
}

@media (max-width: 640px) {
  /* Mobile Flow Visual - Inline horizontal showcase */
  .mobile-flow-visual {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    margin-top: 1rem;
    padding: 1rem;
    background: transparent;
    border-radius: 0.75rem;
  }

  .flow-node {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: var(--landing-surface);
    border: 1px solid var(--landing-border);
    cursor: pointer;
    transition: all 0.3s var(--ease-out-expo);
    -webkit-tap-highlight-color: transparent;
  }

  .flow-node svg {
    width: 20px;
    height: 20px;
  }

  .flow-node:active {
    transform: scale(0.95);
  }

  .rails-node {
    color: #cc0000;
    border-color: rgba(204, 0, 0, 0.3);
  }

  .inertia-node {
    width: 48px;
    height: 48px;
    background: linear-gradient(
      135deg,
      var(--landing-primary) 0%,
      var(--landing-primary-hover) 100%
    );
    color: white;
    border: none;
    box-shadow: 0 2px 8px hsl(var(--landing-shadow-color) / 0.2);
  }

  .inertia-node svg {
    width: 24px;
    height: 24px;
  }

  .react-node {
    color: #61dafb;
    border-color: rgba(97, 218, 251, 0.3);
  }

  .vue-node {
    color: #42b883;
    border-color: rgba(66, 184, 131, 0.3);
  }

  .svelte-node {
    color: #ff3e00;
    border-color: rgba(255, 62, 0, 0.3);
  }

  .flow-node.active {
    transform: scale(1.15);
    box-shadow: 0 0 12px currentColor;
  }

  .flow-arrow {
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--landing-text-muted);
    position: relative;
    width: 40px;
    overflow: visible;
  }

  .flow-arrow::before {
    content: '→';
    font-size: 1.25rem;
    opacity: 0.4;
  }

  .flow-arrow-in {
    height: 40px;
  }

  .flow-arrow-out {
    /* Match frameworks column: 3 icons (40px) + 2 gaps (8px) = 136px */
    height: 136px;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    padding: 8px 0;
  }

  .flow-arrow-out::before {
    display: none;
  }

  .flow-line {
    display: flex;
    align-items: center;
    position: relative;
    height: 24px;
    transform-origin: left center;
  }

  .flow-line::before {
    content: '→';
    font-size: 1.25rem;
    opacity: 0.4;
    color: var(--landing-text-muted);
  }

  .flow-line.top {
    transform: rotate(-15deg);
  }

  .flow-line.middle {
    transform: rotate(0deg);
  }

  .flow-line.bottom {
    transform: rotate(15deg);
  }

  .flow-particle {
    position: absolute;
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: var(--landing-primary);
    opacity: 0;
    left: 0;
    top: 50%;
    margin-top: -3px;
  }

  .flow-arrow-in .flow-particle {
    background: #cc0000;
  }

  /* Color particles to match frameworks */
  .flow-line.top .flow-particle {
    background: #61dafb;
  }
  .flow-line.middle .flow-particle {
    background: #42b883;
  }
  .flow-line.bottom .flow-particle {
    background: #ff3e00;
  }

  /* Default continuous animation */
  .flow-arrow-in .flow-particle {
    animation: particleFlow 1.5s ease-in-out infinite;
  }

  .flow-line .flow-particle {
    animation: particleFlow 1.5s ease-in-out infinite;
  }

  .flow-line.middle .flow-particle {
    animation-delay: 0.2s;
  }

  .flow-line.bottom .flow-particle {
    animation-delay: 0.4s;
  }

  /* Speed boost on tap */
  .mobile-flow-visual.animating .flow-arrow-in .flow-particle,
  .mobile-flow-visual.animating .flow-line .flow-particle {
    animation: particleFlow 0.35s ease-out infinite;
  }

  .mobile-flow-visual.animating .flow-line.middle .flow-particle {
    animation-delay: 0.05s;
  }

  .mobile-flow-visual.animating .flow-line.bottom .flow-particle {
    animation-delay: 0.1s;
  }

  @keyframes particleFlow {
    0% {
      left: 0;
      opacity: 0;
    }
    15% {
      opacity: 1;
    }
    85% {
      opacity: 1;
    }
    100% {
      left: 100%;
      opacity: 0;
    }
  }

  .flow-frameworks {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  /* Highlight specific framework connections */
  .mobile-flow-visual.active-react .react-node,
  .mobile-flow-visual.active-vue .vue-node,
  .mobile-flow-visual.active-svelte .svelte-node {
    transform: scale(1.15);
    box-shadow: 0 0 12px currentColor;
  }

  /* Speed up only the selected framework's particle */
  .mobile-flow-visual.active-react.animating .flow-line.top .flow-particle {
    animation: particleFlow 0.35s ease-out infinite !important;
  }
  .mobile-flow-visual.active-vue.animating .flow-line.middle .flow-particle {
    animation: particleFlow 0.35s ease-out infinite !important;
  }
  .mobile-flow-visual.active-svelte.animating .flow-line.bottom .flow-particle {
    animation: particleFlow 0.35s ease-out infinite !important;
  }

  /* Pause other particles when a framework is selected */
  .mobile-flow-visual.active-react .flow-line.middle .flow-particle,
  .mobile-flow-visual.active-react .flow-line.bottom .flow-particle,
  .mobile-flow-visual.active-vue .flow-line.top .flow-particle,
  .mobile-flow-visual.active-vue .flow-line.bottom .flow-particle,
  .mobile-flow-visual.active-svelte .flow-line.top .flow-particle,
  .mobile-flow-visual.active-svelte .flow-line.middle .flow-particle {
    opacity: 0.3;
  }
}
</style>
