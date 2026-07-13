<script setup lang="ts"></script>

<template>
  <section class="comparison">
    <div class="section-header">
      <h2>Why Inertia?</h2>
      <p>
        Inertia sits between traditional server-rendered apps and full SPAs.
        Here's how it compares.
      </p>
    </div>

    <div class="comparison-grid">
      <!-- vs Hotwire/Turbo -->
      <div class="comparison-card">
        <div class="card-badge hotwire">vs Hotwire</div>
        <h3>Same monolith, different view layer</h3>
        <p class="comparison-intro">
          Both keep you in Rails. Inertia gives you the full React/Vue/Svelte
          ecosystem.
        </p>

        <div class="comparison-table">
          <div class="comparison-row header">
            <span></span>
            <span>Hotwire</span>
            <span class="highlight">Inertia</span>
          </div>
          <div class="comparison-row">
            <span>View layer</span>
            <span>ERB + Stimulus</span>
            <span class="highlight">React/Vue/Svelte</span>
          </div>
          <div class="comparison-row">
            <span>Interactivity</span>
            <span>HTML fragments</span>
            <span class="highlight">Full component state</span>
          </div>
          <div class="comparison-row">
            <span>UI libraries</span>
            <span>Build your own</span>
            <span class="highlight">npm ecosystem</span>
          </div>
        </div>

        <p class="comparison-verdict">
          <strong>Hotwire</strong> for minimal JS and server HTML.<br />
          <strong>Inertia</strong> for modern component architecture.
        </p>
      </div>

      <!-- vs API-first -->
      <div class="comparison-card">
        <div class="card-badge api">vs API + SPA</div>
        <h3>Same frontend, no API hassle</h3>
        <p class="comparison-intro">
          Both give you React/Vue/Svelte. Inertia removes the API layer
          entirely.
        </p>

        <div class="comparison-table">
          <div class="comparison-row header">
            <span></span>
            <span>API + SPA</span>
            <span class="highlight">Inertia</span>
          </div>
          <div class="comparison-row">
            <span>Routing</span>
            <span>Two routers</span>
            <span class="highlight">Rails only</span>
          </div>
          <div class="comparison-row">
            <span>Auth</span>
            <span>JWT/OAuth dance</span>
            <span class="highlight">Rails sessions</span>
          </div>
          <div class="comparison-row">
            <span>Data</span>
            <span>Fetch in useEffect</span>
            <span class="highlight">Props from controller</span>
          </div>
        </div>

        <p class="comparison-verdict">
          <strong>API + SPA</strong> for public APIs or mobile apps.<br />
          <strong>Inertia</strong> for focused web products.
        </p>
      </div>
    </div>
  </section>
</template>

<style scoped>
.comparison {
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

.comparison-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1.5rem;
  max-width: 960px;
  margin: 0 auto;
}

.comparison-card {
  padding: 2rem;
  background: var(--landing-card-bg);
  border: 1px solid var(--landing-border);
  border-radius: 1rem;
  backdrop-filter: blur(12px);
  position: relative;
  transition:
    border-color 0.2s ease,
    box-shadow 0.2s ease;
}

.comparison-card:hover {
  border-color: var(--landing-primary);
  box-shadow: 0 4px 24px hsl(var(--landing-shadow-color) / 0.1);
}

.card-badge {
  display: inline-block;
  padding: 0.25rem 0.625rem;
  border-radius: 9999px;
  font-size: 0.6875rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 0.75rem;
}

.card-badge.hotwire {
  background: rgba(204, 0, 0, 0.1);
  color: #cc0000;
  border: 1px solid rgba(204, 0, 0, 0.2);
}

.card-badge.api {
  background: rgba(99, 102, 241, 0.1);
  color: #6366f1;
  border: 1px solid rgba(99, 102, 241, 0.2);
}

.comparison-card h3 {
  font-size: 1.25rem;
  font-weight: 700;
  margin-bottom: 0.5rem;
  letter-spacing: -0.02em;
}

.comparison-intro {
  color: var(--landing-text-secondary);
  font-size: 0.9375rem;
  margin-bottom: 1.5rem;
  line-height: 1.6;
}

.comparison-table {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
  margin-bottom: 1.5rem;
}

.comparison-row {
  display: grid;
  grid-template-columns: 0.8fr 1fr 1fr;
  gap: 0.75rem;
  padding: 0.625rem 0.75rem;
  background: var(--landing-surface);
  border-radius: 0.5rem;
  font-size: 0.8125rem;
}

.comparison-row.header {
  background: transparent;
  font-weight: 600;
  color: var(--landing-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  font-size: 0.6875rem;
  padding-bottom: 0.25rem;
}

.comparison-row span:first-child {
  color: var(--landing-text-secondary);
  font-weight: 500;
}

.comparison-row span:nth-child(2),
.comparison-row span:nth-child(3) {
  color: var(--landing-text-primary);
}

/* Highlight Inertia column */
.comparison-row span.highlight {
  color: var(--landing-primary);
  font-weight: 600;
}

.comparison-row.header span.highlight {
  color: var(--landing-primary);
}

.comparison-verdict {
  font-size: 0.875rem;
  color: var(--landing-text-secondary);
  line-height: 1.7;
  padding-top: 0.75rem;
  border-top: 1px solid var(--landing-border);
}

.comparison-verdict strong {
  color: var(--landing-text-primary);
}

@media (max-width: 960px) {
  .comparison-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .comparison {
    padding: 3rem 1rem;
  }

  .section-header {
    margin-bottom: 2rem;
  }

  .section-header h2 {
    font-size: 1.75rem;
  }

  .comparison-card {
    padding: 1.25rem;
  }

  .comparison-row {
    font-size: 0.75rem;
    padding: 0.5rem;
    gap: 0.5rem;
  }

  .comparison-row.header {
    font-size: 0.625rem;
  }
}
</style>
