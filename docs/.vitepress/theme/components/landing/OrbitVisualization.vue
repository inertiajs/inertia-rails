<script setup lang="ts">
import { ref } from 'vue'
import {
  IconInertia,
  IconRails,
  IconReact,
  IconSvelte,
  IconVue,
} from '../icons'

const orbitRef = ref<HTMLElement | null>(null)
const isOrbitBoosted = ref(false)

const boostOrbitSpeed = () => {
  isOrbitBoosted.value = true
  if (!orbitRef.value) return

  // Speed up SVG SMIL animations (particles)
  const animations = orbitRef.value.querySelectorAll('animateMotion, animate')
  animations.forEach((anim) => {
    const currentDur = anim.getAttribute('dur')
    if (currentDur && !anim.hasAttribute('data-original-dur')) {
      anim.setAttribute('data-original-dur', currentDur)
    }
    // Speed up by 3x
    const originalDur = anim.getAttribute('data-original-dur') || '2s'
    const durValue = parseFloat(originalDur)
    anim.setAttribute('dur', `${durValue / 3}s`)

    // Also speed up begin delays
    const currentBegin = anim.getAttribute('begin')
    if (currentBegin && !anim.hasAttribute('data-original-begin')) {
      anim.setAttribute('data-original-begin', currentBegin)
    }
    const originalBegin = anim.getAttribute('data-original-begin')
    if (originalBegin) {
      const beginValue = parseFloat(originalBegin)
      anim.setAttribute('begin', `${beginValue / 3}s`)
    }
  })
}

const resetOrbitSpeed = () => {
  isOrbitBoosted.value = false
  if (!orbitRef.value) return

  // Reset SVG SMIL animations
  const animations = orbitRef.value.querySelectorAll('animateMotion, animate')
  animations.forEach((anim) => {
    const originalDur = anim.getAttribute('data-original-dur')
    if (originalDur) {
      anim.setAttribute('dur', originalDur)
    }
    const originalBegin = anim.getAttribute('data-original-begin')
    if (originalBegin) {
      anim.setAttribute('begin', originalBegin)
    }
  })
}

defineExpose({
  orbitRef,
  isOrbitBoosted,
  boostOrbitSpeed,
  resetOrbitSpeed,
})
</script>

<template>
  <div class="value-prop-visual" aria-hidden="true">
    <div
      ref="orbitRef"
      class="orbit"
      :class="{ 'speed-boost': isOrbitBoosted }"
    >
      <!-- Animated data flow paths -->
      <svg
        class="data-flow-svg"
        viewBox="0 0 200 200"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          <!-- Gradient for the flow lines -->
          <linearGradient id="flowGradient" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="rgba(59, 130, 246, 0)" />
            <stop offset="50%" stop-color="rgba(59, 130, 246, 0.6)" />
            <stop offset="100%" stop-color="rgba(59, 130, 246, 0)" />
          </linearGradient>

          <!-- Glow filter -->
          <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="2" result="coloredBlur" />
            <feMerge>
              <feMergeNode in="coloredBlur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          <!-- Soft glow for particles -->
          <filter
            id="particleGlow"
            x="-100%"
            y="-100%"
            width="300%"
            height="300%"
          >
            <feGaussianBlur stdDeviation="1.5" result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        <!-- Static path traces (very subtle) -->
        <path
          class="flow-trace"
          d="M100 26 Q100 60 100 72"
          stroke="rgba(59, 130, 246, 0.08)"
          stroke-width="1"
          fill="none"
        />
        <path
          class="flow-trace"
          d="M128 100 Q145 100 174 100"
          stroke="rgba(97, 218, 251, 0.08)"
          stroke-width="1"
          fill="none"
        />
        <path
          class="flow-trace"
          d="M100 128 Q100 145 100 174"
          stroke="rgba(66, 184, 131, 0.08)"
          stroke-width="1"
          fill="none"
        />
        <path
          class="flow-trace"
          d="M72 100 Q55 100 26 100"
          stroke="rgba(255, 62, 0, 0.08)"
          stroke-width="1"
          fill="none"
        />

        <!-- Incoming flow: Rails to Center -->
        <path
          class="flow-path flow-incoming"
          d="M100 26 Q100 60 100 72"
          stroke="rgba(204, 0, 0, 0.4)"
          stroke-width="1.5"
          fill="none"
          filter="url(#glow)"
        />

        <!-- Outgoing flows: Center to frameworks -->
        <path
          class="flow-path flow-to-react"
          d="M128 100 Q145 100 174 100"
          stroke="rgba(97, 218, 251, 0.4)"
          stroke-width="1.5"
          fill="none"
          filter="url(#glow)"
        />
        <path
          class="flow-path flow-to-vue"
          d="M100 128 Q100 145 100 174"
          stroke="rgba(66, 184, 131, 0.4)"
          stroke-width="1.5"
          fill="none"
          filter="url(#glow)"
        />
        <path
          class="flow-path flow-to-svelte"
          d="M72 100 Q55 100 26 100"
          stroke="rgba(255, 62, 0, 0.4)"
          stroke-width="1.5"
          fill="none"
          filter="url(#glow)"
        />

        <!-- Animated particles -->
        <!-- Rails to Center particle -->
        <circle
          class="particle particle-rails"
          r="2"
          fill="#cc0000"
          filter="url(#particleGlow)"
        >
          <animateMotion
            dur="2s"
            repeatCount="indefinite"
            path="M100 26 Q100 60 100 72"
            keyPoints="0;1"
            keyTimes="0;1"
            calcMode="spline"
            keySplines="0.4 0 0.2 1"
          />
          <animate
            attributeName="opacity"
            values="0;1;1;0"
            keyTimes="0;0.1;0.8;1"
            dur="2s"
            repeatCount="indefinite"
          />
        </circle>

        <!-- Center to React particle -->
        <circle
          class="particle particle-react"
          r="2"
          fill="#61dafb"
          filter="url(#particleGlow)"
        >
          <animateMotion
            dur="2s"
            repeatCount="indefinite"
            begin="0.5s"
            path="M128 100 Q145 100 174 100"
            keyPoints="0;1"
            keyTimes="0;1"
            calcMode="spline"
            keySplines="0.4 0 0.2 1"
          />
          <animate
            attributeName="opacity"
            values="0;1;1;0"
            keyTimes="0;0.1;0.8;1"
            dur="2s"
            begin="0.5s"
            repeatCount="indefinite"
          />
        </circle>

        <!-- Center to Vue particle -->
        <circle
          class="particle particle-vue"
          r="2"
          fill="#42b883"
          filter="url(#particleGlow)"
        >
          <animateMotion
            dur="2s"
            repeatCount="indefinite"
            begin="1s"
            path="M100 128 Q100 145 100 174"
            keyPoints="0;1"
            keyTimes="0;1"
            calcMode="spline"
            keySplines="0.4 0 0.2 1"
          />
          <animate
            attributeName="opacity"
            values="0;1;1;0"
            keyTimes="0;0.1;0.8;1"
            dur="2s"
            begin="1s"
            repeatCount="indefinite"
          />
        </circle>

        <!-- Center to Svelte particle -->
        <circle
          class="particle particle-svelte"
          r="2"
          fill="#ff3e00"
          filter="url(#particleGlow)"
        >
          <animateMotion
            dur="2s"
            repeatCount="indefinite"
            begin="1.5s"
            path="M72 100 Q55 100 26 100"
            keyPoints="0;1"
            keyTimes="0;1"
            calcMode="spline"
            keySplines="0.4 0 0.2 1"
          />
          <animate
            attributeName="opacity"
            values="0;1;1;0"
            keyTimes="0;0.1;0.8;1"
            dur="2s"
            begin="1.5s"
            repeatCount="indefinite"
          />
        </circle>

        <!-- Secondary particles for fuller effect -->
        <circle
          class="particle particle-rails-2"
          r="1.5"
          fill="#cc0000"
          filter="url(#particleGlow)"
        >
          <animateMotion
            dur="2s"
            repeatCount="indefinite"
            begin="1s"
            path="M100 26 Q100 60 100 72"
            keyPoints="0;1"
            keyTimes="0;1"
            calcMode="spline"
            keySplines="0.4 0 0.2 1"
          />
          <animate
            attributeName="opacity"
            values="0;0.7;0.7;0"
            keyTimes="0;0.1;0.8;1"
            dur="2s"
            begin="1s"
            repeatCount="indefinite"
          />
        </circle>

        <circle
          class="particle particle-react-2"
          r="1.5"
          fill="#61dafb"
          filter="url(#particleGlow)"
        >
          <animateMotion
            dur="2s"
            repeatCount="indefinite"
            begin="1.5s"
            path="M128 100 Q145 100 174 100"
            keyPoints="0;1"
            keyTimes="0;1"
            calcMode="spline"
            keySplines="0.4 0 0.2 1"
          />
          <animate
            attributeName="opacity"
            values="0;0.7;0.7;0"
            keyTimes="0;0.1;0.8;1"
            dur="2s"
            begin="1.5s"
            repeatCount="indefinite"
          />
        </circle>
      </svg>

      <div class="orbit-ring"></div>
      <div class="orbit-dot rails">
        <IconRails />
      </div>
      <div class="orbit-dot react">
        <IconReact />
      </div>
      <div class="orbit-dot vue">
        <IconVue />
      </div>
      <div class="orbit-dot svelte">
        <IconSvelte />
      </div>
      <div
        class="orbit-center"
        @mouseenter="boostOrbitSpeed"
        @mouseleave="resetOrbitSpeed"
      >
        <IconInertia />
      </div>
    </div>
  </div>
</template>

<style scoped>
.value-prop-visual {
  position: relative;
  z-index: 1;
  padding: 2rem;
}

.orbit {
  position: relative;
  width: 200px;
  height: 200px;
}

/* Animated data flow SVG */
.data-flow-svg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  z-index: 0;
  pointer-events: none;
}

/* Flow path animations with stroke-dasharray */
.flow-path {
  stroke-dasharray: 8 12;
  stroke-linecap: round;
}

.flow-incoming {
  animation: flowDash 2s linear infinite;
}

.flow-to-react {
  animation: flowDash 2s linear infinite;
  animation-delay: 0.5s;
}

.flow-to-vue {
  animation: flowDash 2s linear infinite;
  animation-delay: 1s;
}

.flow-to-svelte {
  animation: flowDash 2s linear infinite;
  animation-delay: 1.5s;
}

@keyframes flowDash {
  0% {
    stroke-dashoffset: 40;
    opacity: 0.3;
  }
  50% {
    opacity: 0.6;
  }
  100% {
    stroke-dashoffset: 0;
    opacity: 0.3;
  }
}

/* Particle styles */
.particle {
  will-change: transform, opacity;
}

.orbit-ring {
  position: absolute;
  inset: 0;
  border: 1px dashed var(--landing-border);
  border-radius: 50%;
  opacity: 0.6;
}

.orbit-center {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%) scale(1);
  width: 56px;
  height: 56px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(
    135deg,
    var(--landing-primary) 0%,
    var(--landing-primary-hover) 100%
  );
  border-radius: 50%;
  color: white;
  box-shadow: 0 4px 16px hsl(var(--landing-shadow-color) / 0.2);
  animation: centerPulse 2s ease-in-out infinite;
  cursor: pointer;
  transition:
    transform 0.3s ease,
    box-shadow 0.3s ease;
}

.orbit-center:hover {
  transform: translate(-50%, -50%) scale(1.1);
  box-shadow: var(--landing-hover-shadow);
}

@keyframes centerPulse {
  0%,
  100% {
    box-shadow: 0 4px 16px hsl(var(--landing-shadow-color) / 0.2);
  }
  50% {
    box-shadow:
      0 4px 24px hsl(var(--landing-shadow-color) / 0.25),
      0 0 8px hsl(var(--landing-shadow-color) / 0.1);
  }
}

/* Speed boost on center hover - affects all orbit animations */
.orbit.speed-boost .flow-path {
  animation-duration: 0.7s;
}

.orbit.speed-boost .flow-path.flow-incoming {
  animation-delay: 0s;
}

.orbit.speed-boost .flow-path.flow-to-react {
  animation-delay: 0.15s;
}

.orbit.speed-boost .flow-path.flow-to-vue {
  animation-delay: 0.3s;
}

.orbit.speed-boost .flow-path.flow-to-svelte {
  animation-delay: 0.45s;
}

/* Intensify glow on hover */
.orbit.speed-boost .flow-trace {
  stroke-opacity: 0.25;
  transition: stroke-opacity 0.3s ease;
}

.orbit.speed-boost .flow-path {
  stroke-width: 2;
  opacity: 0.8;
  transition:
    stroke-width 0.3s ease,
    opacity 0.3s ease;
}

/* Smooth transition for flow elements */
.flow-path,
.flow-trace {
  transition:
    stroke-width 0.3s ease,
    stroke-opacity 0.3s ease,
    opacity 0.3s ease;
}

.orbit-center svg {
  width: 28px;
  height: 28px;
}

.orbit-dot {
  position: absolute;
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--landing-surface);
  border: 1px solid var(--landing-border);
  border-radius: 50%;
  backdrop-filter: blur(8px);
  transition: all 0.3s var(--ease-out-expo);
}

.orbit-dot svg {
  width: 26px;
  height: 26px;
}

.orbit-dot.rails {
  top: -22px;
  left: 50%;
  transform: translateX(-50%);
  color: #cc0000;
  border-color: rgba(204, 0, 0, 0.2);
}
.orbit-dot.rails:hover {
  transform: translateX(-50%) scale(1.15);
  border-color: rgba(204, 0, 0, 0.5);
  box-shadow: 0 2px 8px rgba(204, 0, 0, 0.15);
}

.orbit-dot.react {
  top: 50%;
  right: -22px;
  transform: translateY(-50%);
  color: #61dafb;
  border-color: rgba(97, 218, 251, 0.2);
}
.orbit-dot.react:hover {
  transform: translateY(-50%) scale(1.15);
  border-color: rgba(97, 218, 251, 0.5);
  box-shadow: 0 2px 8px rgba(97, 218, 251, 0.15);
}

.orbit-dot.vue {
  bottom: -22px;
  left: 50%;
  transform: translateX(-50%);
  color: #42b883;
  border-color: rgba(66, 184, 131, 0.2);
}
.orbit-dot.vue:hover {
  transform: translateX(-50%) scale(1.15);
  border-color: rgba(66, 184, 131, 0.5);
  box-shadow: 0 2px 8px rgba(66, 184, 131, 0.15);
}

.orbit-dot.svelte {
  top: 50%;
  left: -22px;
  transform: translateY(-50%);
  color: #ff3e00;
  border-color: rgba(255, 62, 0, 0.2);
}
.orbit-dot.svelte:hover {
  transform: translateY(-50%) scale(1.15);
  border-color: rgba(255, 62, 0, 0.5);
  box-shadow: 0 2px 8px rgba(255, 62, 0, 0.15);
}

@media (max-width: 640px) {
  .value-prop-visual {
    display: none;
  }
}

@media (prefers-reduced-motion: reduce) {
  /* Hide animated data flow for reduced motion */
  .data-flow-svg .flow-path,
  .data-flow-svg .particle {
    display: none;
  }

  .orbit-center {
    animation: none;
  }

  .orbit-center:hover {
    transform: translate(-50%, -50%) scale(1);
  }
}
</style>
