import { createInertiaApp } from '@inertiajs/svelte'
import  { mount } from 'svelte';

createInertiaApp({
  // Set default page title
  // see https://inertia-rails.netlify.app/guide/title-and-meta
  //
  // title: title => title ? `${title} - App` : 'App',

  // Disable progress bar
  //
  // see https://inertia-rails.netlify.app/guide/progress-indicators
  // progress: false,

  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.svelte', { eager: true })
    return pages[`../pages/${name}.svelte`]

    // To use a default layout, import the Layout component
    // and use the following lines.
    // see https://inertia-rails.netlify.app/guide/pages#default-layouts
    //
    // const page = pages[`../pages/${name}.svelte`]
    // return { default: page.default, layout: page.layout || Layout }
  },

  setup({ el, App, props }) {
    mount(App, { target: el, props })
  },
})
