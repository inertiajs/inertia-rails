import { createInertiaApp } from '@inertiajs/inertia-svelte'
import { InertiaProgress } from '@inertiajs/progress'

document.addEventListener('DOMContentLoaded', () => {
  InertiaProgress.init()

  createInertiaApp({
    id: 'app',
    resolve: name => import(`../Pages/${name}.svelte`),
    setup({ el, App, props }) {
      new App({ target: el, props })
    },
  })
})
