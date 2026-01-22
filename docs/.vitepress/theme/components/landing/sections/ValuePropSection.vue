<script setup lang="ts">
import MobileFlowVisualization from '../MobileFlowVisualization.vue'
import OrbitVisualization from '../OrbitVisualization.vue'
</script>

<template>
  <section class="value-prop">
    <div class="value-prop-card">
      <div class="value-prop-content">
        <span class="value-prop-eyebrow">The Inertia&nbsp;Way</span>
        <h2>
          Your&nbsp;controllers. Your&nbsp;routes. Modern&nbsp;components.
        </h2>
        <p>
          Pass data from Rails directly to React, Vue, or Svelte as&nbsp;props.
          No&nbsp;REST&nbsp;endpoints. No&nbsp;GraphQL.
          No&nbsp;state&nbsp;management&nbsp;headaches.
        </p>
      </div>
      <OrbitVisualization />
      <MobileFlowVisualization />
    </div>
  </section>
</template>

<style scoped>
.value-prop {
  padding: 4rem 1.5rem;
  max-width: var(--landing-max-width);
  margin: 0 auto;
  position: relative;
  z-index: 1;
}

.value-prop-card {
  display: grid;
  grid-template-columns: 1fr auto;
  align-items: center;
  gap: 3rem;
  padding: 3rem;
  background: var(--landing-card-bg);
  border: 1px solid var(--landing-border);
  border-radius: 1.5rem;
  backdrop-filter: blur(12px);
  position: relative;
}

.value-prop-card::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(
    135deg,
    var(--landing-primary-glow) 0%,
    transparent 50%
  );
  opacity: 0.5;
  pointer-events: none;
  border-radius: inherit;
}

.value-prop-content {
  position: relative;
  z-index: 1;
}

.value-prop-eyebrow {
  display: inline-block;
  padding: 0.375rem 0.875rem;
  background: var(--landing-primary-subtle);
  border: 1px solid var(--landing-primary);
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--landing-primary);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 1.25rem;
}

.value-prop h2 {
  font-size: clamp(1.5rem, 3vw, 2rem);
  font-weight: 800;
  margin-bottom: 0.875rem;
  letter-spacing: -0.03em;
  line-height: 1.2;
}

.value-prop p {
  color: var(--landing-text-secondary);
  font-size: 1rem;
  line-height: 1.7;
  margin: 0;
  max-width: 480px;
}

@media (max-width: 640px) {
  .value-prop {
    padding: 1.5rem 1rem;
  }

  .value-prop-card {
    grid-template-columns: 1fr;
    padding: 1.5rem 1.25rem;
    text-align: center;
  }

  .value-prop p {
    max-width: none;
  }
}
</style>
