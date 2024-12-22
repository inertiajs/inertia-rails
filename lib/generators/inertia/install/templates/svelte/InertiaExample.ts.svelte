<script lang="ts">
  import svelteSvg from '/assets/svelte.svg'
  import inertiaSvg from '/assets/inertia.svg'
  import viteRubySvg from '/assets/vite_ruby.svg'

  let { name }: { name: string } = $props()

  let count = $state(0)
</script>

<svelte:head>
  <title>Inertia + Vite Ruby + Svelte Example</title>
</svelte:head>

<div class="inertia_example">
  <h1>Hello {name}!</h1>

  <div>
    <a href="https://inertia-rails.dev" target="_blank">
      <img class="logo" src={inertiaSvg} alt="Inertia logo" />
    </a>
    <a href="https://vite-ruby.netlify.app" target="_blank">
      <img class="logo vite" src={viteRubySvg} alt="Vite Ruby logo" />
    </a>
    <a href="https://svelte.dev" target="_blank">
      <img class="logo svelte" src={svelteSvg} alt="Svelte logo" />
    </a>
  </div>

  <h2>Inertia + Vite Ruby + Svelte</h2>

  <div class="card">
    <button onclick={() => count++}>
      count is {count}
    </button>
    <p>
      Edit <code>app/frontend/pages/InertiaExample.svelte</code> and save to test
      HMR
    </p>
  </div>
  <p class="read-the-docs">
    Click on the Inertia, Vite Ruby, and Svelte logos to learn more
  </p>
</div>

<style>
  .inertia_example {
    font-family: Inter, system-ui, Avenir, Helvetica, Arial, sans-serif;
    line-height: 1.5;
    font-weight: 400;
    color: #213547;
    background-color: #ffffff;
    max-width: 1280px;
    margin: 0 auto;
    padding: 2rem;
    text-align: center;
  }

  h1 {
    font-size: 3.2em;
    line-height: 1.1;
  }

  h2 {
    font-size: 2.6em;
    line-height: 1.1;
  }

  button {
    border-radius: 8px;
    border: 1px solid transparent;
    padding: 0.6em 1.2em;
    font-size: 1em;
    font-weight: 500;
    font-family: inherit;
    background-color: #f9f9f9;
    cursor: pointer;
    transition: border-color 0.25s;
  }
  button:hover {
    border-color: #646cff;
  }
  button:focus,
  button:focus-visible {
    outline: 4px auto -webkit-focus-ring-color;
  }

  .logo {
    display: inline-block;
    height: 6em;
    padding: 1.5em;
    will-change: filter;
    transition: filter 300ms;
  }
  .logo:hover {
    filter: drop-shadow(0 0 2em #646cffaa);
  }
  .logo.vite:hover {
    filter: drop-shadow(0 0 2em #e4023baa);
  }
  .logo.svelte:hover {
    filter: drop-shadow(0 0 2em #ff3e00aa);
  }

  .card {
    padding: 2em;
  }

  .read-the-docs {
    color: #888;
  }
</style>
