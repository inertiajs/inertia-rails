<template>
  <Head title="Ruby on Rails + Inertia + Vue" />

  <div class="root">
    <nav class="subNav">
      <a href="https://rubyonrails.org" target="_blank">
        <img class="logo rails" :src="railsSvg" alt="Ruby on Rails Logo" />
      </a>
      <a href="https://inertia-rails.dev" target="_blank">
        <img class="logo inertia" :src="inertiaSvg" alt="Inertia logo" />
      </a>
      <a href="https://vuejs.org" target="_blank">
        <img class="logo vue" :src="vueSvg" alt="Vue logo"/>
      </a>
    </nav>

    <div class="footer">
      <div class="card">
        <p>
          Edit <code><%= js_destination_path %>/pages/inertia_example/index.ts.vue</code> and save to test <abbr title="Hot Module Replacement">HMR</abbr>.
        </p>
      </div>

      <ul>
        <li>
          <ul>
            <li><strong>Rails version:</strong> {{ rails_version }}</li>
            <li><strong>Rack version:</strong> {{ rack_version }}</li>
          </ul>
        </li>
        <li><strong>Ruby version:</strong> {{ ruby_version }}</li>
        <li>
          <ul>
            <li><strong>Inertia Rails version:</strong> {{ inertia_rails_version }}</li>
            <li><strong>Vue version:</strong> {{ vue_version }}</li>
          </ul>
        </li>
        </ul>
    </div>
  </div>
</template>

<script setup>
import { Head } from '@inertiajs/vue3'
import { version as vue_version } from 'vue';

import railsSvg from '/assets/rails.svg'
import inertiaSvg from '/assets/inertia.svg'
import vueSvg from '/assets/vue.svg'

defineProps({
  rails_version: String,
  rack_version: String,
  ruby_version: String,
  inertia_rails_version: String,
})
</script>

<style global>
  body {
    margin: 0;
    padding: 0;
  }
</style>

<style scoped>
.root {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  align-items: center;
  background-color: #F0E7E9;
  background-image: url(data:image/svg+xml;base64,PHN2ZyBoZWlnaHQ9IjEwMjQiIHZpZXdCb3g9IjAgMCAxNDQwIDEwMjQiIHdpZHRoPSIxNDQwIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Im0xNDQwIDUxMC4wMDA2NDh2LTUxMC4wMDA2NDhoLTE0NDB2Mzg0LjAwMDY0OGM0MTcuMzExOTM5IDEzMS4xNDIxNzkgODkxIDE3MS41MTMgMTQ0MCAxMjZ6IiBmaWxsPSIjZmZmIi8+PC9zdmc+);
  background-position: center center;
  background-repeat: no-repeat;
  background-size: cover;
  color: #261B23;
  display: flex;
  flex-direction: column;
  font-family: Sans-Serif;
  font-size: calc(0.9em + 0.5vw);
  font-style: normal;
  font-weight: 400;
  justify-content: center;
  line-height: 1.25;
  min-height: 100vh;
  text-align: center;
}

@media (prefers-color-scheme: dark) {
  .root {
    background-color: #1a1a1a;
    background-image: url(data:image/svg+xml;base64,PHN2ZyBoZWlnaHQ9IjEwMjQiIHZpZXdCb3g9IjAgMCAxNDQwIDEwMjQiIHdpZHRoPSIxNDQwIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Im0xNDQwIDUxMC4wMDA2NDh2LTUxMC4wMDA2NDhoLTE0NDB2Mzg0LjAwMDY0OGM0MTcuMzExOTM5IDEzMS4xNDIxNzkgODkxIDE3MS41MTMgMTQ0MCAxMjZ6IiBmaWxsPSIjMzMzIi8+PC9zdmc+);
    color: #e0e0e0;
  }
}

.logo {
  display: inline-block;
  height: 9.8vw;
  min-height: 130px;
  padding: 1.5em;
  will-change: filter;
  transition: filter 300ms;
  filter: drop-shadow(0 20px 13px rgb(0 0 0 / 0.03)) drop-shadow(0 8px 5px rgb(0 0 0 / 0.08));
}
.logo.inertia:hover {
  filter: drop-shadow(0 0 2em #646cffaa);
}
.logo.vue:hover {
  filter: drop-shadow(0 0 2em #61dafbaa);
}
.logo.rails:hover {
  filter: drop-shadow(0 0 2em rgb(211 0 1 / 0.6));
}

@media (prefers-color-scheme: dark) {
  .logo {
    filter: drop-shadow(0 20px 13px rgb(255 255 255 / 0.03)) drop-shadow(0 8px 5px rgb(255 255 255 / 0.08));
  }
}

.card {
  padding: 2em;
  font-size: 0.7em;
  color: #948e90;
}

.footer {
  bottom: 0;
  left: 0;
  margin: 0 2rem 2rem 2rem;
  position: absolute;
  right: 0;
}

.footer ul {
  list-style: none;
}

.footer ul li {
  display: inline;
}

.footer ul ul li:after {
  content: " | ";
  font-weight: 300;
  color: #948e90;
}

.footer ul ul li:last-child:after {
  content: "";
}
</style>
