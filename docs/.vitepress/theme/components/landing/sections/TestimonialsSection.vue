<script setup lang="ts">
const testimonials = [
  {
    quote:
      "Rails + Inertia.js + Postgres—it's the perfect stack for our AI overlords.",
    author: 'Josh Pigford',
    role: 'Founder of Baremetrics',
    url: 'https://x.com/Shpigford',
  },
  {
    quote:
      'Full power of modern frontend frameworks, with the simplicity of Rails.',
    author: 'Irina Nazarova',
    role: 'CEO of Evil Martians',
    url: 'https://evilmartians.com/chronicles/keeping-rails-cool-the-modern-frontend-toolkit',
  },
]
</script>

<template>
  <section class="testimonials">
    <div class="testimonials-grid">
      <a
        v-for="testimonial in testimonials"
        :key="testimonial.author"
        :href="testimonial.url"
        target="_blank"
        rel="noopener"
        class="testimonial-card"
      >
        <blockquote>
          <p>"{{ testimonial.quote }}"</p>
        </blockquote>
        <div class="testimonial-author">
          <span class="author-name">{{ testimonial.author }}</span>
          <span class="author-role">{{ testimonial.role }}</span>
        </div>
      </a>
    </div>
  </section>
</template>

<style scoped>
.testimonials {
  padding: 4rem 1.5rem;
  max-width: var(--landing-max-width);
  margin: 0 auto;
  position: relative;
  z-index: 1;
}

.testimonials-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1.5rem;
  max-width: 900px;
  margin: 0 auto;
}

.testimonial-card {
  padding: 2rem;
  background: var(--landing-card-bg);
  border: 1px solid var(--landing-border);
  border-radius: 1rem;
  backdrop-filter: blur(12px);
  text-decoration: none;
  color: inherit;
  transition: all 0.3s var(--ease-out-expo);
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.testimonial-card:hover {
  border-color: var(--landing-hover-border);
  transform: translateY(-4px);
  box-shadow: var(--landing-hover-shadow);
}

.testimonial-card:focus-visible {
  outline: 2px solid var(--landing-primary);
  outline-offset: 2px;
}

.testimonial-card blockquote {
  margin: 0;
  flex: 1;
}

.testimonial-card blockquote p {
  font-size: 1.125rem;
  font-weight: 500;
  line-height: 1.6;
  color: var(--landing-text-primary);
  margin: 0;
}

.testimonial-author {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.author-name {
  font-weight: 700;
  font-size: 0.9375rem;
  color: var(--landing-text-primary);
}

.author-role {
  font-size: 0.8125rem;
  color: var(--landing-text-secondary);
}

@media (max-width: 768px) {
  .testimonials-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .testimonials {
    padding: 2rem 1rem;
  }

  .testimonial-card {
    padding: 1.5rem;
  }

  .testimonial-card blockquote p {
    font-size: 1rem;
  }
}
</style>
