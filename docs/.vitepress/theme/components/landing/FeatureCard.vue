<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'

defineProps<{
  icon: string
  title: string
  desc: string
  link: string
  size: 'large' | 'small'
  index: number
}>()

const cardRef = ref<HTMLElement | null>(null)
const isVisible = ref(false)
const mouseX = ref(0)
const mouseY = ref(0)
const isHovering = ref(false)
let observer: IntersectionObserver | null = null

// Icon mapping for consistent styling
const iconMap: Record<string, string> = {
  'form-input':
    'M4 5a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V5ZM4 13a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v6a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-6ZM16 13a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v6a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-6Z',
  zap: 'M13 2L3 14h9l-1 8 10-12h-9l1-8z',
  'check-circle': 'M22 11.08V12a10 10 0 1 1-5.93-9.14M22 4 12 14.01l-3-3',
  'refresh-cw':
    'M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15',
  package:
    'M16.5 9.4 7.55 4.24M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16zM3.27 6.96 12 12.01l8.73-5.05M12 22.08V12',
  clock:
    'M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10zM12 6v6l4 2',
  terminal: 'M4 17l6-6-6-6M12 19h8',
  lock: 'M19 11H5a2 2 0 0 0-2 2v7a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7a2 2 0 0 0-2-2ZM7 11V7a5 5 0 0 1 10 0v4',
}

function handleMouseMove(e: MouseEvent) {
  if (!cardRef.value) return
  const rect = cardRef.value.getBoundingClientRect()
  mouseX.value = e.clientX - rect.left
  mouseY.value = e.clientY - rect.top
}

function handleMouseEnter() {
  isHovering.value = true
}

function handleMouseLeave() {
  isHovering.value = false
}

onMounted(() => {
  if (!cardRef.value) return

  // Check for reduced motion preference
  if (typeof window !== 'undefined') {
    const prefersReducedMotion = window.matchMedia(
      '(prefers-reduced-motion: reduce)',
    ).matches
    if (prefersReducedMotion) {
      isVisible.value = true
      return
    }
  }

  observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          isVisible.value = true
          observer?.unobserve(entry.target)
        }
      })
    },
    { threshold: 0.1, rootMargin: '50px' },
  )

  observer.observe(cardRef.value)
})

onUnmounted(() => {
  observer?.disconnect()
})
</script>

<template>
  <a
    ref="cardRef"
    :href="link"
    class="feature-card"
    :class="[size, { visible: isVisible, hovering: isHovering }]"
    :style="{
      '--delay': `${index * 50}ms`,
      '--mouse-x': `${mouseX}px`,
      '--mouse-y': `${mouseY}px`,
    }"
    @mousemove="handleMouseMove"
    @mouseenter="handleMouseEnter"
    @mouseleave="handleMouseLeave"
  >
    <!-- Spotlight gradient that follows mouse -->
    <span class="spotlight" aria-hidden="true" />

    <!-- Animated border glow -->
    <span class="border-glow" aria-hidden="true" />

    <!-- Shimmer effect -->
    <span class="shimmer" aria-hidden="true" />

    <!-- Content -->
    <span class="card-content">
      <span class="icon" aria-hidden="true">
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path :d="iconMap[icon] || iconMap['check-circle']" />
        </svg>
      </span>
      <h3>{{ title }}</h3>
      <p>{{ desc }}</p>
    </span>
  </a>
</template>

<style scoped>
.feature-card {
  padding: 1.75rem;
  background: var(--landing-card-bg, rgba(21, 21, 24, 0.6));
  border: 1px solid var(--landing-border, rgba(255, 255, 255, 0.06));
  border-radius: 1rem;
  text-decoration: none;
  color: inherit;
  display: block;
  backdrop-filter: blur(12px);
  position: relative;
  overflow: hidden;

  /* Animation initial state */
  opacity: 0;
  transform: translate3d(0, 24px, 0);
  transition:
    opacity 0.6s cubic-bezier(0.16, 1, 0.3, 1) var(--delay, 0ms),
    transform 0.6s cubic-bezier(0.16, 1, 0.3, 1) var(--delay, 0ms),
    box-shadow 0.4s cubic-bezier(0.16, 1, 0.3, 1),
    border-color 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

.feature-card.visible {
  opacity: 1;
  transform: translate3d(0, 0, 0);
}

.feature-card:hover {
  box-shadow: var(
    --landing-hover-shadow,
    0 4px 12px -4px rgba(15, 23, 42, 0.1)
  );
  border-color: var(--landing-hover-border, rgba(148, 163, 184, 0.4));
  transform: translate3d(0, -4px, 0);
}

.feature-card:focus-visible {
  outline: 2px solid var(--landing-primary, #3b82f6);
  outline-offset: 2px;
}

.feature-card.large {
  grid-column: span 2;
}

/* Spotlight effect - follows mouse */
.spotlight {
  position: absolute;
  inset: 0;
  opacity: 0;
  background: radial-gradient(
    350px circle at var(--mouse-x) var(--mouse-y),
    var(--landing-card-glow, rgba(148, 163, 184, 0.15)),
    transparent 60%
  );
  transition: opacity 0.4s ease;
  pointer-events: none;
  z-index: 1;
}

.feature-card.hovering .spotlight {
  opacity: 1;
}

/* Animated border glow */
.border-glow {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  opacity: 0;
  transition: opacity 0.4s ease;
  pointer-events: none;
  z-index: 0;
}

.border-glow::before {
  content: '';
  position: absolute;
  inset: -1px;
  border-radius: inherit;
  padding: 1px;
  background: linear-gradient(
    135deg,
    var(--landing-card-glow, rgba(148, 163, 184, 0.2)) 0%,
    transparent 40%,
    transparent 60%,
    var(--landing-card-glow, rgba(148, 163, 184, 0.2)) 100%
  );
  -webkit-mask:
    linear-gradient(#fff 0 0) content-box,
    linear-gradient(#fff 0 0);
  mask:
    linear-gradient(#fff 0 0) content-box,
    linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
  animation: borderRotate 4s linear infinite paused;
}

.feature-card.hovering .border-glow {
  opacity: 1;
}

.feature-card.hovering .border-glow::before {
  animation-play-state: running;
}

@keyframes borderRotate {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}

/* Shimmer effect */
.shimmer {
  position: absolute;
  inset: 0;
  opacity: 0;
  overflow: hidden;
  pointer-events: none;
  z-index: 2;
}

.shimmer::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 50%;
  height: 100%;
  background: linear-gradient(
    90deg,
    transparent,
    rgba(255, 255, 255, 0.03),
    transparent
  );
  transform: skewX(-20deg);
}

.feature-card.hovering .shimmer {
  opacity: 1;
}

.feature-card.hovering .shimmer::before {
  animation: shimmerMove 1.5s ease-in-out;
}

@keyframes shimmerMove {
  0% {
    left: -100%;
  }
  100% {
    left: 200%;
  }
}

/* Card content */
.card-content {
  position: relative;
  z-index: 3;
  display: block;
}

.icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 3rem;
  height: 3rem;
  margin-bottom: 1.25rem;
  padding: 0.625rem;
  background: var(--landing-primary-subtle, rgba(59, 130, 246, 0.1));
  border-radius: 0.75rem;
  color: var(--landing-primary, #3b82f6);
  transition:
    transform 0.3s cubic-bezier(0.16, 1, 0.3, 1),
    background 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  position: relative;
}

/* Subtle glow pulse on icon */
.icon::after {
  content: '';
  position: absolute;
  inset: -4px;
  border-radius: inherit;
  background: radial-gradient(
    circle,
    var(--landing-card-glow, rgba(148, 163, 184, 0.15)),
    transparent 70%
  );
  opacity: 0;
  transition: opacity 0.3s ease;
  z-index: -1;
}

.feature-card.hovering .icon::after {
  opacity: 1;
  animation: iconPulse 2s ease-in-out infinite;
}

@keyframes iconPulse {
  0%,
  100% {
    transform: scale(1);
    opacity: 0.6;
  }
  50% {
    transform: scale(1.15);
    opacity: 1;
  }
}

.feature-card:hover .icon {
  transform: scale(1.1);
  background: var(--landing-primary-subtle, rgba(59, 130, 246, 0.12));
}

.icon svg {
  width: 1.25rem;
  height: 1.25rem;
}

h3 {
  font-size: 1.0625rem;
  font-weight: 700;
  margin-bottom: 0.625rem;
  color: var(--landing-text-primary, #fafafa);
  letter-spacing: -0.02em;
}

p {
  color: var(--landing-text-secondary, #a1a1aa);
  font-size: 0.875rem;
  line-height: 1.6;
  margin: 0;
}

@media (prefers-reduced-motion: reduce) {
  .feature-card {
    opacity: 1;
    transform: none;
    transition:
      box-shadow 0.2s ease,
      border-color 0.2s ease;
  }

  .feature-card:hover .icon {
    transform: none;
  }

  .spotlight,
  .border-glow,
  .shimmer {
    display: none;
  }

  .icon::after {
    display: none;
  }
}

@media (max-width: 960px) {
  .feature-card.large {
    grid-column: span 1;
  }
}
</style>
