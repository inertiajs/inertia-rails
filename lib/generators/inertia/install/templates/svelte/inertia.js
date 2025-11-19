import { createInertiaApp } from '@inertiajs/svelte'
import  { mount } from 'svelte';

createInertiaApp({
  // Disable progress bar
  //
  // see https://inertia-rails.dev/guide/progress-indicators
  // progress: false,

  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.svelte', {
      eager: true,
    })
    const page = pages[`../pages/${name}.svelte`]
    if (!page) {
      console.error(`Missing Inertia page component: '${name}.svelte'`)
    }

    // To use a default layout, import the Layout component
    // and use the following line.
    // see https://inertia-rails.dev/guide/pages#default-layouts
    //
    // return { default: page.default, layout: page.layout || Layout }

    return page
  },

  setup({ el, App, props }) {
    if (el) {
      mount(App, { target: el, props })
    } else {
      console.error(
        "Missing root element.\n\n" +
        "If you see this error, it probably means you load Inertia.js on non-Inertia pages.\n" +
        'Consider moving <%= vite_javascript_tag "inertia" %> to the Inertia-specific layout instead.',
      )
    }
  },

  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: true,
    },
    future: {
      useDataInertiaHeadAttribute: true,
      useDialogForErrorModal: true,
      preserveEqualProps: true,
    },
  },
})
