<script setup lang="ts">
import { ref } from 'vue'

const faqs = [
  {
    question: 'Do I need to build an API?',
    answer:
      'No. Controllers pass data directly to components as props—no endpoints, no client-side fetching. Need a public API later? Add it alongside Inertia whenever you want.',
  },
  {
    question: 'Can I use my existing Rails authentication?',
    answer:
      'Yes. Devise, Clearance, custom auth—whatever you use today works unchanged. Inertia uses <a href="/guide/authentication">Rails sessions</a>, so there\'s no token management to deal with.',
  },
  {
    question: 'What about SEO and server-side rendering?',
    answer:
      '<a href="/guide/server-side-rendering">SSR</a> gives you fast first paint and full SEO. It runs a small Node.js process alongside Rails—the <a href="/guide/starter-kits">starter kits</a> set this up for you.',
  },
  {
    question: 'Can I migrate incrementally?',
    answer:
      'Yes. ERB views and Inertia pages coexist fine. Convert one page at a time. No big-bang rewrite required.',
  },
  {
    question: 'Is Inertia only for Laravel?',
    answer:
      'No. Inertia started in the Laravel ecosystem, but this adapter is actively maintained and works the same way.',
  },
  {
    question: 'What if I need a mobile app later?',
    answer:
      'Wrap your Inertia app with <a href="https://capacitorjs.com/" target="_blank" rel="noopener">Capacitor</a> for native mobile/desktop—no API needed. Or add API endpoints alongside Inertia—they work fine together.',
  },
  {
    question: 'Is it suitable for large-scale apps?',
    answer:
      'Yes. <a href="/guide/partial-reloads">Partial reloads</a>, <a href="/guide/code-splitting">code splitting</a>, and <a href="/guide/deferred-props">deferred props</a> keep large apps fast. Load only what you need, when you need it.',
  },
]

const openIndex = ref<number | null>(null)

const toggle = (index: number) => {
  openIndex.value = openIndex.value === index ? null : index
}
</script>

<template>
  <section class="faq">
    <div class="section-header">
      <h2>Frequently asked questions</h2>
      <p>Common questions about using Inertia with Rails.</p>
    </div>

    <div class="faq-list">
      <div
        v-for="(faq, index) in faqs"
        :key="index"
        class="faq-item"
        :class="{ open: openIndex === index }"
      >
        <button class="faq-question" @click="toggle(index)">
          <span>{{ faq.question }}</span>
          <span class="faq-icon" aria-hidden="true">
            <svg
              width="20"
              height="20"
              viewBox="0 0 20 20"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M5 7.5L10 12.5L15 7.5"
                stroke="currentColor"
                stroke-width="1.5"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
          </span>
        </button>
        <div class="faq-answer">
          <p v-html="faq.answer"></p>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.faq {
  padding: 6rem 1.5rem;
  max-width: var(--landing-max-width);
  margin: 0 auto;
  position: relative;
  z-index: 1;
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
  text-wrap: balance;
}

.section-header p {
  color: var(--landing-text-secondary);
  font-size: 1.125rem;
  max-width: 540px;
  margin: 0 auto;
  line-height: 1.7;
}

.faq-list {
  max-width: 720px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.faq-item {
  background: var(--landing-card-bg);
  border: 1px solid var(--landing-border);
  border-radius: 0.75rem;
  overflow: hidden;
  transition: border-color 0.2s ease;
}

.faq-item:hover {
  border-color: var(--landing-hover-border);
}

.faq-item.open {
  border-color: var(--landing-primary);
}

.faq-question {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1.25rem 1.5rem;
  background: none;
  border: none;
  cursor: pointer;
  text-align: left;
  font-size: 1rem;
  font-weight: 600;
  color: var(--landing-text-primary);
  transition: color 0.2s ease;
}

.faq-question:hover {
  color: var(--landing-primary);
}

.faq-icon {
  flex-shrink: 0;
  color: var(--landing-text-muted);
  transition:
    transform 0.3s var(--ease-out-expo),
    color 0.2s ease;
}

.faq-item.open .faq-icon {
  transform: rotate(180deg);
  color: var(--landing-primary);
}

.faq-answer {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows 0.3s var(--ease-out-expo);
}

.faq-item.open .faq-answer {
  grid-template-rows: 1fr;
}

.faq-answer p {
  overflow: hidden;
  padding: 0 1.5rem;
  margin: 0;
  font-size: 0.9375rem;
  line-height: 1.7;
  color: var(--landing-text-secondary);
  transition: padding 0.3s var(--ease-out-expo);
}

.faq-item.open .faq-answer p {
  padding: 0 1.5rem 1.25rem;
}

.faq-answer :deep(a) {
  color: var(--landing-primary);
  text-decoration: none;
  font-weight: 500;
  transition: opacity 0.15s ease;
}

.faq-answer :deep(a:hover) {
  opacity: 0.8;
  text-decoration: underline;
}

@media (max-width: 640px) {
  .faq {
    padding: 3rem 1rem;
  }

  .section-header {
    margin-bottom: 2rem;
  }

  .section-header h2 {
    font-size: 1.75rem;
  }

  .faq-question {
    padding: 1rem 1.25rem;
    font-size: 0.9375rem;
  }

  .faq-answer p {
    padding: 0 1.25rem;
    font-size: 0.875rem;
  }

  .faq-item.open .faq-answer p {
    padding: 0 1.25rem 1rem;
  }
}
</style>
