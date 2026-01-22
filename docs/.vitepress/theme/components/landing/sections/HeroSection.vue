<script setup lang="ts">
import { IconGithub } from '../../icons'
import CodePanels from '../CodePanels.vue'
</script>

<template>
  <section class="hero">
    <div class="hero-content">
      <div class="hero-badges">
        <a
          href="https://github.com/inertiajs/inertia-rails"
          target="_blank"
          rel="noopener"
          class="github-stars"
          aria-label="Star inertia-rails on GitHub"
        >
          <IconGithub />
          <span>1k+ stars on GitHub</span>
        </a>
      </div>
      <h1>Build frontend experiences with the&nbsp;backend you&nbsp;love</h1>
      <p class="subheadline">
        Build single-page applications using your existing Rails controllers,
        routes, and authentication. No&nbsp;API&nbsp;required.
      </p>
      <div class="hero-ctas">
        <a href="/guide/server-side-setup" class="cta-primary"
          >Add to Your Rails App</a
        >
        <a
          href="https://github.com/inertiajs/inertia-rails"
          target="_blank"
          rel="noopener"
          class="cta-secondary"
        >
          <IconGithub class="cta-icon" />
          <span class="cta-text">GitHub</span>
        </a>
      </div>
    </div>

    <CodePanels />
  </section>
</template>

<style scoped>
.hero {
  padding: 6rem 1.5rem;
  max-width: var(--landing-max-width);
  margin: 0 auto;
  position: relative;
  z-index: 1;
  min-height: auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding-top: 5rem;
  padding-bottom: 3rem;
  gap: 2.5rem;
}

.hero-content {
  max-width: 760px;
  padding: 0 1.5rem;
}

.hero-badges {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 1.25rem;
}

.github-stars {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: var(--landing-surface);
  border: 1px solid var(--landing-border);
  border-radius: 9999px;
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--landing-text-secondary);
  text-decoration: none;
  backdrop-filter: blur(8px);
  transition: all 0.3s var(--ease-out-expo);
}

.github-stars:hover {
  color: var(--landing-text-primary);
  border-color: var(--landing-text-muted);
  transform: translateY(-1px);
}

.github-stars svg {
  width: 1rem;
  height: 1rem;
}

.hero h1 {
  font-size: clamp(2.25rem, 5vw, 3.5rem);
  font-weight: 800;
  line-height: 1.1;
  letter-spacing: -0.03em;
  margin-bottom: 1rem;
  padding-bottom: 0.05em;
  text-wrap: balance;
}

.subheadline {
  font-size: 1.125rem;
  color: var(--landing-text-secondary);
  line-height: 1.6;
  margin-bottom: 1.5rem;
  max-width: 540px;
  margin-left: auto;
  margin-right: auto;
}

.hero-ctas {
  display: flex;
  gap: 0.75rem;
  justify-content: center;
  flex-wrap: wrap;
}

.cta-primary,
.cta-secondary {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.875rem 1.75rem;
  border-radius: 0.75rem;
  font-weight: 600;
  font-size: 0.9375rem;
  text-decoration: none;
  transition: all 0.3s var(--ease-out-expo);
}

.cta-primary {
  background: linear-gradient(
    135deg,
    var(--landing-primary) 0%,
    var(--landing-primary-hover) 100%
  );
  color: white;
  border: 1px solid transparent;
  box-shadow:
    0 1px 4px hsl(var(--landing-shadow-color) / 0.15),
    inset 0 1px 0 rgba(255, 255, 255, 0.1);
}

.cta-primary:hover {
  transform: translateY(-2px);
  box-shadow:
    0 4px 16px hsl(var(--landing-shadow-color) / 0.2),
    inset 0 1px 0 rgba(255, 255, 255, 0.15);
}

.cta-secondary {
  background: var(--landing-surface);
  color: var(--landing-text-primary);
  border: 1px solid var(--landing-border);
  backdrop-filter: blur(8px);
}

.cta-secondary:hover {
  background: var(--landing-card-bg);
  border-color: var(--landing-text-muted);
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
}

.cta-icon {
  width: 1.25rem;
  height: 1.25rem;
  flex-shrink: 0;
}

@media (max-width: 640px) {
  .hero {
    min-height: auto;
    padding-top: 3rem;
    gap: 1.25rem;
  }

  .hero-ctas {
    gap: 0.75rem;
  }

  .cta-primary,
  .cta-secondary {
    padding: 0.75rem 1.25rem;
    font-size: 0.875rem;
  }

  .cta-text {
    display: none;
  }

  .cta-icon {
    width: 1.5rem;
    height: 1.5rem;
  }

  .cta-secondary {
    padding: 0.75rem;
  }
}

@media (max-width: 480px) {
  .hero h1 {
    font-size: 1.875rem;
  }

  .subheadline {
    font-size: 1rem;
  }
}
</style>
