import { createInertiaApp } from '@inertiajs/react'
import { createElement, ReactNode } from 'react'
import { createRoot } from 'react-dom/client'

// Temporary type definition, until @inertiajs/react provides one
type ResolvedComponent = {
  default: ReactNode
  layout?: (page: ReactNode) => ReactNode
}

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
    const pages = import.meta.glob<ResolvedComponent>('../pages/**/*.tsx', {
      eager: true,
    })
    const page = pages[`../pages/${name}.tsx`]
    if (!page) {
      console.error(`Missing Inertia page component: '${name}.tsx'`)
    }

    // To use a default layout, import the Layout component
    // and use the following line.
    // see https://inertia-rails.dev/guide/pages#default-layouts
    //
    // page.default.layout ||= (page) => createElement(Layout, null, page)

    return page
  },

  setup({ el, App, props }) {
    if (el) {
      createRoot(el).render(createElement(App, props))
    } else {
      console.error(
        'Missing root element.\n\n' +
          'If you see this error, it probably means you load Inertia.js on non-Inertia pages.\n' +
          'Consider moving <%%= vite_typescript_tag "inertia" %> to the Inertia-specific layout instead.',
      )
    }
  },
})
