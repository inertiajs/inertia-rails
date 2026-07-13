<script setup lang="ts">
import { IconDiscord, IconGithub, IconStar } from '../../icons'
</script>

<template>
  <section class="community">
    <div class="section-header">
      <h2>Join the&nbsp;community</h2>
      <p>
        Get help, share what you're building, and learn from real-world
        Inertia&nbsp;Rails applications.
      </p>
    </div>
    <div class="community-links">
      <a href="/awesome" class="community-link">
        <span class="link-icon" aria-hidden="true">
          <IconStar />
        </span>
        <span class="link-text">
          <span class="link-title">Awesome Inertia&nbsp;Rails</span>
          <span class="link-desc">Gems, tutorials, and real&nbsp;apps</span>
        </span>
      </a>
      <a
        href="https://discord.gg/inertiajs"
        target="_blank"
        rel="noopener"
        class="community-link"
      >
        <span class="link-icon" aria-hidden="true">
          <IconDiscord />
        </span>
        <span class="link-text">
          <span class="link-title">Discord&nbsp;Community</span>
          <span class="link-desc">Ask questions, get answers&nbsp;fast</span>
        </span>
      </a>
      <a
        href="https://github.com/inertiajs/inertia-rails"
        target="_blank"
        rel="noopener"
        class="community-link"
      >
        <span class="link-icon" aria-hidden="true">
          <IconGithub />
        </span>
        <span class="link-text">
          <span class="link-title">Star on&nbsp;GitHub</span>
          <span class="link-desc">Browse the source, open&nbsp;issues</span>
        </span>
      </a>
    </div>
  </section>
</template>

<style scoped>
.community {
  padding: 6rem 1.5rem;
  max-width: var(--landing-max-width);
  margin: 0 auto;
  position: relative;
  z-index: 1;
  padding-top: 6rem;
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

.community-links {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.25rem;
  max-width: 960px;
  margin: 0 auto;
}

.community-link {
  display: flex;
  align-items: center;
  gap: 1.25rem;
  padding: 1.5rem;
  background: var(--landing-card-bg);
  border: 1px solid var(--landing-border);
  border-radius: 1rem;
  text-decoration: none;
  color: inherit;
  backdrop-filter: blur(12px);
  transition: all 0.3s var(--ease-out-expo);
}

.community-link:hover {
  border-color: var(--landing-hover-border);
  transform: translateY(-4px);
  box-shadow: var(--landing-hover-shadow);
}

.community-link:focus-visible {
  outline: 2px solid var(--landing-primary);
  outline-offset: 2px;
}

.link-icon {
  width: 3rem;
  height: 3rem;
  flex-shrink: 0;
  padding: 0.625rem;
  background: var(--landing-primary-subtle);
  border-radius: 0.75rem;
  color: var(--landing-primary);
  transition: all 0.3s var(--ease-out-expo);
}

.community-link:hover .link-icon {
  transform: scale(1.1);
  background: var(--landing-primary-subtle);
}

.link-icon svg {
  width: 100%;
  height: 100%;
}

.link-text {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.link-title {
  font-weight: 700;
  font-size: 0.9375rem;
  letter-spacing: -0.01em;
}

.link-desc {
  font-size: 0.8125rem;
  color: var(--landing-text-secondary);
}

@media (max-width: 960px) {
  .community-links {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .community {
    padding-top: 2.5rem;
    padding-bottom: 2rem;
  }

  .section-header {
    margin-bottom: 2rem;
  }

  .section-header h2 {
    font-size: 1.75rem;
  }

  .community-links {
    gap: 0.75rem;
  }

  .community-link {
    padding: 1rem;
    gap: 1rem;
  }
}
</style>
