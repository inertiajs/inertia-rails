<script setup lang="ts">
import { features } from '../../../data/features'
import FeatureCard from '../FeatureCard.vue'
</script>

<template>
  <section class="features">
    <div class="section-header">
      <h2>Built for real Rails&nbsp;apps</h2>
      <p>
        Form handling, SSR, testing helpers, and&nbsp;more. Everything
        you&nbsp;need to ship production apps with&nbsp;confidence.
      </p>
    </div>
    <div class="features-grid">
      <FeatureCard
        v-for="(feature, i) in features"
        :key="feature.title"
        :icon="feature.icon"
        :title="feature.title"
        :desc="feature.desc"
        :link="feature.link"
        :size="feature.size"
        :index="i"
      />
    </div>
  </section>
</template>

<style scoped>
.features {
  padding: 6rem 1.5rem;
  max-width: var(--landing-max-width);
  margin: 0 auto;
  position: relative;
  z-index: 1;
  padding-top: 6rem;
}

/* Soft gradient glow for features section */
.features::before {
  content: '';
  position: absolute;
  top: -100px;
  left: 50%;
  transform: translateX(-50%);
  width: 100%;
  max-width: 1000px;
  height: 600px;
  background: radial-gradient(
    ellipse at center,
    var(--landing-primary-glow) 0%,
    transparent 60%
  );
  pointer-events: none;
  z-index: 0;
  opacity: 0.8;
}

.section-header {
  text-align: center;
  margin-bottom: 4rem;
  position: relative;
  z-index: 1;
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

.features-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1rem;
  position: relative;
  z-index: 1;
}

@media (max-width: 960px) {
  .features-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 640px) {
  .features {
    padding-top: 2rem;
    padding-bottom: 2rem;
  }

  .section-header {
    margin-bottom: 2rem;
  }

  .section-header h2 {
    font-size: 1.75rem;
  }

  .features-grid {
    grid-template-columns: 1fr;
    gap: 0.75rem;
  }

  /* Staggered horizontal offset - creates diagonal rhythm */
  .features-grid > :nth-child(odd) {
    margin-right: 2rem;
  }

  .features-grid > :nth-child(even) {
    margin-left: 2rem;
  }

  /* Full-width accent cards for variety */
  .features-grid > :first-child,
  .features-grid > :nth-child(5) {
    margin-left: 0;
    margin-right: 0;
  }
}
</style>
