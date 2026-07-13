<script setup lang="ts">
import { ref } from 'vue'
import {
  IconInertia,
  IconRails,
  IconReact,
  IconSvelte,
  IconVue,
} from '../icons'

const flowRef = ref<HTMLElement | null>(null)

// Hover states
const hoveredNode = ref<string | null>(null)

const setHovered = (node: string | null) => {
  hoveredNode.value = node
}

defineExpose({
  flowRef,
  hoveredNode,
})
</script>

<template>
  <div
    ref="flowRef"
    class="flow-visual"
    :class="{
      'hover-rails': hoveredNode === 'rails',
      'hover-inertia': hoveredNode === 'inertia',
      'hover-react': hoveredNode === 'react',
      'hover-vue': hoveredNode === 'vue',
      'hover-svelte': hoveredNode === 'svelte',
    }"
  >
    <button
      class="flow-node rails-node"
      aria-label="Rails"
      @mouseenter="setHovered('rails')"
      @mouseleave="setHovered(null)"
      @focus="setHovered('rails')"
      @blur="setHovered(null)"
    >
      <IconRails />
    </button>
    <div class="flow-arrow flow-arrow-in">
      <span class="flow-particle"></span>
    </div>
    <button
      class="flow-node inertia-node"
      aria-label="Inertia"
      @mouseenter="setHovered('inertia')"
      @mouseleave="setHovered(null)"
      @focus="setHovered('inertia')"
      @blur="setHovered(null)"
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
        aria-label="React"
        @mouseenter="setHovered('react')"
        @mouseleave="setHovered(null)"
        @focus="setHovered('react')"
        @blur="setHovered(null)"
      >
        <IconReact />
      </button>
      <button
        class="flow-node vue-node"
        aria-label="Vue"
        @mouseenter="setHovered('vue')"
        @mouseleave="setHovered(null)"
        @focus="setHovered('vue')"
        @blur="setHovered(null)"
      >
        <IconVue />
      </button>
      <button
        class="flow-node svelte-node"
        aria-label="Svelte"
        @mouseenter="setHovered('svelte')"
        @mouseleave="setHovered(null)"
        @focus="setHovered('svelte')"
        @blur="setHovered(null)"
      >
        <IconSvelte />
      </button>
    </div>
  </div>
</template>

<style scoped>
/* Flow Visual - Inline horizontal showcase */
.flow-visual {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1.5rem;
  gap: 0;
}

.flow-visual > .flow-node {
  flex-shrink: 0;
}

.flow-visual > .flow-arrow {
  flex-shrink: 0;
}

.flow-node {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: var(--landing-surface);
  border: 1px solid var(--landing-border);
  cursor: pointer;
  transition: all 0.3s var(--ease-out-expo);
  -webkit-tap-highlight-color: transparent;
}

.flow-node svg {
  width: 24px;
  height: 24px;
}

.flow-node:hover {
  transform: scale(1.1);
}

.flow-node:active {
  transform: scale(0.95);
}

.rails-node {
  color: #cc0000;
  border-color: rgba(204, 0, 0, 0.3);
}

.rails-node:hover {
  border-color: rgba(204, 0, 0, 0.6);
  box-shadow: 0 2px 12px rgba(204, 0, 0, 0.2);
}

.inertia-node {
  width: 56px;
  height: 56px;
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
  width: 28px;
  height: 28px;
}

.inertia-node:hover {
  box-shadow: 0 4px 16px hsl(var(--landing-shadow-color) / 0.3);
}

.react-node {
  color: #61dafb;
  border-color: rgba(97, 218, 251, 0.3);
}

.react-node:hover {
  border-color: rgba(97, 218, 251, 0.6);
  box-shadow: 0 2px 12px rgba(97, 218, 251, 0.2);
}

.vue-node {
  color: #42b883;
  border-color: rgba(66, 184, 131, 0.3);
}

.vue-node:hover {
  border-color: rgba(66, 184, 131, 0.6);
  box-shadow: 0 2px 12px rgba(66, 184, 131, 0.2);
}

.svelte-node {
  color: #ff3e00;
  border-color: rgba(255, 62, 0, 0.3);
}

.svelte-node:hover {
  border-color: rgba(255, 62, 0, 0.6);
  box-shadow: 0 2px 12px rgba(255, 62, 0, 0.2);
}

.flow-arrow {
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--landing-text-muted);
  position: relative;
  width: 48px;
  overflow: visible;
  margin: 0 0.5rem;
}

.flow-arrow::before {
  content: '→';
  font-size: 1.5rem;
  opacity: 0.4;
}

.flow-arrow-in {
  height: 48px;
}

.flow-arrow-out {
  height: 168px;
  width: 100px;
  position: relative;
  margin: 0 0.25rem;
}

.flow-arrow-out::before {
  display: none;
}

.flow-line {
  display: block;
  position: absolute;
  left: 0;
  top: 50%;
  width: 100%;
  height: 2px;
  transform-origin: left center;
}

.flow-line::before {
  content: '→';
  font-size: 1.5rem;
  opacity: 0.4;
  color: var(--landing-text-muted);
  transition: opacity 0.3s ease;
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
}

.flow-line.top {
  transform: rotate(-26deg);
}

.flow-line.middle {
  transform: rotate(0deg);
}

.flow-line.bottom {
  transform: rotate(26deg);
}

/* Particles */
.flow-particle {
  position: absolute;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--landing-primary);
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  transition: opacity 0.3s ease;
}

.flow-arrow-in .flow-particle {
  background: #cc0000;
}

.flow-line.top .flow-particle {
  background: #61dafb;
}
.flow-line.middle .flow-particle {
  background: #42b883;
}
.flow-line.bottom .flow-particle {
  background: #ff3e00;
}

/* Default animation - synced, normal speed */
.flow-arrow-in .flow-particle,
.flow-line .flow-particle {
  animation: particleFlow 2s ease-in-out infinite;
}

@keyframes particleFlow {
  0% {
    left: 0;
    opacity: 0;
  }
  10% {
    opacity: 1;
  }
  90% {
    opacity: 1;
  }
  100% {
    left: 100%;
    opacity: 0;
  }
}

/* === HOVER STATES === */

/* Rails hover: Speed up ALL particles (data flows through entire system) */
.flow-visual.hover-rails .flow-arrow-in .flow-particle,
.flow-visual.hover-rails .flow-line .flow-particle {
  animation: particleFlow 0.4s ease-out infinite;
}

.flow-visual.hover-rails .rails-node {
  transform: scale(1.15);
  box-shadow: 0 0 20px rgba(204, 0, 0, 0.4);
}

/* Inertia hover: Speed up ALL particles */
.flow-visual.hover-inertia .flow-arrow-in .flow-particle,
.flow-visual.hover-inertia .flow-line .flow-particle {
  animation: particleFlow 0.4s ease-out infinite;
}

.flow-visual.hover-inertia .inertia-node {
  transform: scale(1.15);
  box-shadow: 0 0 24px hsl(var(--landing-shadow-color) / 0.4);
}

/* React hover: Speed up Rails + React particles, hide other FE particles */
.flow-visual.hover-react .flow-arrow-in .flow-particle,
.flow-visual.hover-react .flow-line.top .flow-particle {
  animation: particleFlow 0.4s ease-out infinite;
}

.flow-visual.hover-react .flow-line.middle .flow-particle,
.flow-visual.hover-react .flow-line.bottom .flow-particle {
  animation: none;
  opacity: 0;
}

.flow-visual.hover-react .flow-line.middle::before,
.flow-visual.hover-react .flow-line.bottom::before {
  opacity: 0.15;
}

.flow-visual.hover-react .react-node {
  transform: scale(1.15);
  box-shadow: 0 0 20px rgba(97, 218, 251, 0.5);
}

/* Vue hover: Speed up Rails + Vue particles, hide other FE particles */
.flow-visual.hover-vue .flow-arrow-in .flow-particle,
.flow-visual.hover-vue .flow-line.middle .flow-particle {
  animation: particleFlow 0.4s ease-out infinite;
}

.flow-visual.hover-vue .flow-line.top .flow-particle,
.flow-visual.hover-vue .flow-line.bottom .flow-particle {
  animation: none;
  opacity: 0;
}

.flow-visual.hover-vue .flow-line.top::before,
.flow-visual.hover-vue .flow-line.bottom::before {
  opacity: 0.15;
}

.flow-visual.hover-vue .vue-node {
  transform: scale(1.15);
  box-shadow: 0 0 20px rgba(66, 184, 131, 0.5);
}

/* Svelte hover: Speed up Rails + Svelte particles, hide other FE particles */
.flow-visual.hover-svelte .flow-arrow-in .flow-particle,
.flow-visual.hover-svelte .flow-line.bottom .flow-particle {
  animation: particleFlow 0.4s ease-out infinite;
}

.flow-visual.hover-svelte .flow-line.top .flow-particle,
.flow-visual.hover-svelte .flow-line.middle .flow-particle {
  animation: none;
  opacity: 0;
}

.flow-visual.hover-svelte .flow-line.top::before,
.flow-visual.hover-svelte .flow-line.middle::before {
  opacity: 0.15;
}

.flow-visual.hover-svelte .svelte-node {
  transform: scale(1.15);
  box-shadow: 0 0 20px rgba(255, 62, 0, 0.5);
}

.flow-frameworks {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

@media (max-width: 640px) {
  .flow-visual {
    zoom: 0.75;
  }
}

@media (prefers-reduced-motion: reduce) {
  .flow-particle {
    display: none;
  }

  .flow-node:hover {
    transform: none;
  }
}
</style>
