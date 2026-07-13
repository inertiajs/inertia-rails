<script setup lang="ts"></script>

<template>
  <footer class="landing-footer">
    <div class="footer-links">
      <div class="footer-section">
        <h4>Documentation</h4>
        <a href="/guide/">Getting Started</a>
        <a href="/guide/server-side-setup">Server-side Setup</a>
        <a href="/guide/client-side-setup">Client-side Setup</a>
        <a href="/guide/forms">Forms</a>
      </div>
      <div class="footer-section">
        <h4>Community</h4>
        <a href="https://discord.gg/inertiajs" target="_blank" rel="noopener"
          >Discord</a
        >
        <a
          href="https://github.com/inertiajs/inertia-rails"
          target="_blank"
          rel="noopener"
          >GitHub</a
        >
        <a
          href="https://github.com/inertiajs/inertia-rails/issues"
          target="_blank"
          rel="noopener"
          >Issues</a
        >
        <a href="/awesome">Awesome Inertia</a>
      </div>
      <div class="footer-section">
        <h4>More</h4>
        <a href="https://inertiajs.com" target="_blank" rel="noopener"
          >Inertia.js</a
        >
        <a
          href="https://github.com/inertiajs/inertia-rails/blob/master/CHANGELOG.md"
          target="_blank"
          rel="noopener"
          >Changelog</a
        >
        <a
          href="https://github.com/inertiajs/inertia-rails/blob/master/LICENSE.txt"
          target="_blank"
          rel="noopener"
          >MIT License</a
        >
      </div>
    </div>
    <div class="footer-bottom">
      <p>Released under the MIT License.</p>
    </div>
  </footer>
</template>

<style scoped>
.landing-footer {
  padding: 4rem 1.5rem 2rem;
  border-top: 1px solid var(--landing-border);
  max-width: var(--landing-max-width);
  margin: 0 auto;
  position: relative;
  z-index: 1;
}

.footer-links {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 3rem;
  margin-bottom: 3rem;
}

.footer-section h4 {
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--landing-text-primary);
  margin-bottom: 1rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.footer-section a {
  display: block;
  font-size: 0.875rem;
  color: var(--landing-text-secondary);
  text-decoration: none;
  padding: 0.375rem 0;
  transition: color 0.2s ease;
}

.footer-section a:hover {
  color: var(--landing-text-primary);
}

.footer-bottom {
  padding-top: 2rem;
  border-top: 1px solid var(--landing-border);
  text-align: center;
}

.footer-bottom p {
  font-size: 0.8125rem;
  color: var(--landing-text-muted);
}

@media (max-width: 960px) {
  .footer-links {
    grid-template-columns: 1fr;
    gap: 2rem;
    text-align: center;
  }
}

@media (max-width: 640px) {
  .landing-footer {
    padding: 2rem 1rem 1.5rem;
  }
}
</style>
