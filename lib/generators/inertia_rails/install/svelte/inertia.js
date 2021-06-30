import axios from 'axios'

import { createInertiaApp } from '@inertiajs/inertia-svelte'
import { InertiaProgress } from '@inertiajs/progress'

document.addEventListener('DOMContentLoaded', () => {
  const csrfToken = document.querySelector('meta[name=csrf-token]').content
  axios.defaults.headers.common['X-CSRF-Token'] = csrfToken

  InertiaProgress.init()

  createInertiaApp({
    id: 'app',
    resolve: name => import(`../Pages/${name}.svelte`),
    setup({ el, App, props }) {
      new App({ target: el, props })
    },
  })
})