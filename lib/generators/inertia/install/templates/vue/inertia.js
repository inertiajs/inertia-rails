import { createInertiaApp } from '@inertiajs/vue3'
import { createApp, h } from 'vue'

createInertiaApp({
  // Set default page title
  // see https://inertia-rails.dev/guide/title-and-meta
  //
  // title: title => title ? `${title} - App` : 'App',

  // Disable progress bar
  //
  // see https://inertia-rails.dev/guide/progress-indicators
  // progress: false,

  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.vue', {
      eager: true,
    })
    return pages[`../pages/${name}.vue`]

    // To use a default layout, import the Layout component
    // and use the following lines.
    // see https://inertia-rails.dev/guide/pages#default-layouts
    //
    // const page = pages[`../pages/${name}.vue`]
    // page.default.layout = page.default.layout || Layout
    // return page
  },

  setup({ el, App, props, plugin }) {
    createApp({ render: () => h(App, props) })
      .use(plugin)
      .mount(el)
  },
})
