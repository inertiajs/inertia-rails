import axios from 'axios'
import Vue from 'vue'

import { app, plugin } from '@inertiajs/inertia-vue'
import { InertiaProgress } from '@inertiajs/progress'

document.addEventListener('DOMContentLoaded', () => {
  const csrfToken = document.querySelector('meta[name=csrf-token]').content
  axios.defaults.headers.common['X-CSRF-Token'] = csrfToken

  InertiaProgress.init();
  const el = document.getElementById('app')

  Vue.use(plugin)

  new Vue({
    render: h => h(app, {
      props: {
        initialPage: JSON.parse(el.dataset.page),
        resolveComponent: name => require(`../Pages/${name}`).default,
      },
    }),
  }).$mount(el)
})
