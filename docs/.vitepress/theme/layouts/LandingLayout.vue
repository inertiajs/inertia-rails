<script setup lang="ts">
import CommunitySection from '../components/landing/sections/CommunitySection.vue'
import FeaturesSection from '../components/landing/sections/FeaturesSection.vue'
import GettingStartedSection from '../components/landing/sections/GettingStartedSection.vue'
import HeroSection from '../components/landing/sections/HeroSection.vue'
import LandingFooter from '../components/landing/sections/LandingFooter.vue'
import ValuePropSection from '../components/landing/sections/ValuePropSection.vue'
</script>

<template>
  <div class="landing-page">
    <!-- Skip link for accessibility -->
    <a href="#main" class="skip-link">Skip to main content</a>

    <main id="main">
      <HeroSection />
      <ValuePropSection />
      <GettingStartedSection />
      <FeaturesSection />
      <CommunitySection />
    </main>

    <LandingFooter />
  </div>
</template>

<style>
/* Light mode (default) */
.landing-page {
  /* Backgrounds - subtle cool gradient */
  --landing-bg: #f8fafc;
  --landing-bg-gradient: linear-gradient(
    180deg,
    #ffffff 0%,
    #f8fafc 50%,
    #f1f5f9 100%
  );
  --landing-surface: rgba(255, 255, 255, 0.85);
  --landing-card-bg: rgba(255, 255, 255, 0.7);
  --landing-border: rgba(148, 163, 184, 0.2);

  /* Brand colors - Blue primary */
  --landing-primary: #2563eb;
  --landing-primary-hover: #1d4ed8;
  /* Light theme: no colored glows, use subtle neutral shadows */
  --landing-primary-glow: transparent;
  --landing-primary-subtle: rgba(37, 99, 235, 0.05);
  /* Layered shadow using hue-matched color (slate-blue 220deg) */
  --landing-shadow-color: 220deg 30% 50%;
  --landing-hover-shadow:
    0 2px 4px -2px hsl(var(--landing-shadow-color) / 0.12),
    0 4px 8px -2px hsl(var(--landing-shadow-color) / 0.08);
  --landing-hover-border: rgba(148, 163, 184, 0.5);
  --landing-card-glow: transparent;

  /* Accent - Red (rare use: badge only) */
  --landing-accent: #dc2626;
  --landing-accent-hover: #b91c1c;
  --landing-accent-glow: rgba(220, 38, 38, 0.15);

  /* Text */
  --landing-text-primary: #0f172a;
  --landing-text-secondary: #475569;
  --landing-text-muted: #94a3b8;

  /* Gradients - cool blue tones only */
  --gradient-mesh-1: rgba(219, 234, 254, 0.6);
  --gradient-mesh-2: rgba(224, 231, 255, 0.5);
  --gradient-mesh-3: rgba(241, 245, 249, 0.7);

  /* Code panels */
  --landing-code-bg: rgba(255, 255, 255, 0.9);
  --landing-code-bg-hover: rgba(240, 240, 248, 0.95);
  --landing-code-header: linear-gradient(
    180deg,
    rgba(250, 250, 252, 0.98) 0%,
    rgba(245, 245, 250, 0.98) 100%
  );
  --landing-code-content: rgba(252, 252, 254, 0.8);
  --landing-code-border: rgba(0, 0, 0, 0.08);
  --landing-code-tab-bg: rgba(0, 0, 0, 0.04);
  --landing-code-shadow: none;
  --landing-code-shadow-hover: 0 0 0 1px var(--landing-primary);

  /* Layout */
  --landing-max-width: 1200px;

  /* Easing functions */
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-out-quart: cubic-bezier(0.25, 1, 0.5, 1);
  --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);
}

/* Dark mode */
:root.dark .landing-page {
  --landing-bg: #050506;
  --landing-bg-gradient: #050506;
  --landing-surface: rgba(17, 17, 19, 0.8);
  --landing-card-bg: rgba(21, 21, 24, 0.6);
  --landing-border: rgba(255, 255, 255, 0.06);

  --landing-primary: #3b82f6;
  --landing-primary-hover: #60a5fa;
  --landing-primary-glow: rgba(59, 130, 246, 0.12);
  --landing-primary-subtle: rgba(59, 130, 246, 0.08);
  --landing-shadow-color: 220deg 80% 60%;
  --landing-hover-shadow:
    0 4px 12px -4px hsl(var(--landing-shadow-color) / 0.25),
    0 8px 24px -4px hsl(var(--landing-shadow-color) / 0.15);
  --landing-hover-border: rgba(59, 130, 246, 0.25);
  --landing-card-glow: rgba(59, 130, 246, 0.15);

  --landing-accent: #ef4444;
  --landing-accent-hover: #f87171;
  --landing-accent-glow: rgba(239, 68, 68, 0.25);

  --landing-text-primary: #fafafa;
  --landing-text-secondary: #a1a1aa;
  --landing-text-muted: #52525b;

  --gradient-mesh-1: rgba(37, 99, 235, 0.15);
  --gradient-mesh-2: rgba(220, 38, 38, 0.1);
  --gradient-mesh-3: rgba(139, 92, 246, 0.1);

  /* Code panels */
  --landing-code-bg: rgba(24, 24, 27, 0.8);
  --landing-code-bg-hover: rgba(28, 28, 32, 0.85);
  --landing-code-header: linear-gradient(
    180deg,
    rgba(32, 32, 36, 0.95) 0%,
    rgba(26, 26, 30, 0.95) 100%
  );
  --landing-code-content: rgba(18, 18, 21, 0.6);
  --landing-code-border: rgba(255, 255, 255, 0.08);
  --landing-code-tab-bg: rgba(255, 255, 255, 0.06);
  --landing-code-shadow:
    0 4px 24px rgba(0, 0, 0, 0.2), 0 1px 4px rgba(0, 0, 0, 0.15);
  --landing-code-shadow-hover:
    0 4px 24px rgba(0, 0, 0, 0.2), 0 1px 4px rgba(0, 0, 0, 0.15),
    0 0 0 1px rgba(59, 130, 246, 0.1), 0 0 16px rgba(59, 130, 246, 0.05);
}

/* Skip link - visually hidden until focused */
.skip-link {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
  background: var(--landing-primary);
  color: white;
  text-decoration: none;
  font-weight: 600;
  font-size: 0.875rem;
  z-index: 9999;
}

.skip-link:focus {
  position: fixed;
  top: 1rem;
  left: 1rem;
  width: auto;
  height: auto;
  padding: 0.75rem 1.5rem;
  margin: 0;
  overflow: visible;
  clip: auto;
  white-space: normal;
  border-radius: 0.5rem;
  outline: 2px solid var(--landing-primary-hover);
  outline-offset: 2px;
  box-shadow: 0 2px 12px hsl(var(--landing-shadow-color) / 0.15);
}

/* Base Layout */
.landing-page {
  background: var(--landing-bg-gradient, var(--landing-bg));
  color: var(--landing-text-primary);
  min-height: 100vh;
  position: relative;
  overflow-x: hidden;
}

/* Gradient mesh background */
.landing-page::before {
  content: '';
  position: fixed;
  inset: 0;
  background:
    radial-gradient(
      ellipse 60% 50% at 10% 20%,
      var(--gradient-mesh-1),
      transparent 50%
    ),
    radial-gradient(
      ellipse 50% 40% at 90% 10%,
      var(--gradient-mesh-2),
      transparent 50%
    ),
    radial-gradient(
      ellipse 40% 50% at 50% 80%,
      var(--gradient-mesh-3),
      transparent 50%
    );
  pointer-events: none;
  z-index: 0;
}

/* Subtle noise texture */
.landing-page::after {
  content: '';
  position: fixed;
  inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E");
  opacity: 0.03;
  pointer-events: none;
  z-index: 0;
}

/* Reduced motion */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
</style>
