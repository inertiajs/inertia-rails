# Client-side setup

Once you have your [server-side framework configured](/guide/server-side-setup.md), you then need to setup your client-side framework. Inertia currently provides support for React, Vue, and Svelte.

> [!NOTE]
> You can skip this step if you have already executed the [Rails generator](/guide/server-side-setup#rails-generator).

## Install dependencies

First, install the Inertia client-side adapter corresponding to your framework of choice.

:::tabs key:frameworks
== Vue

```shell
npm install @inertiajs/vue3 vue
```

== React

```shell
npm install @inertiajs/react react react-dom
```

== Svelte 4|Svelte 5

```shell
npm install @inertiajs/svelte svelte
```

:::

## Initialize the Inertia app

Next, update your main JavaScript file to boot your Inertia app. To accomplish this, we'll use the `createInertiaApp` function to initialize the client-side framework with the base Inertia component.

:::tabs key:frameworks
== Vue

```js
// frontend/entrypoints/inertia.js
import { createApp, h } from 'vue'
import { createInertiaApp } from '@inertiajs/vue3'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.vue', { eager: true })
    return pages[`../pages/${name}.vue`]
  },
  setup({ el, App, props, plugin }) {
    createApp({ render: () => h(App, props) })
      .use(plugin)
      .mount(el)
  },
})
```

== React

```js
// frontend/entrypoints/inertia.js
import { createInertiaApp } from '@inertiajs/react'
import { createElement } from 'react'
import { createRoot } from 'react-dom/client'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.jsx', { eager: true })
    return pages[`../pages/${name}.jsx`]
  },
  setup({ el, App, props }) {
    const root = createRoot(el)
    root.render(createElement(App, props))
  },
})
```

== Svelte 4

```js
// frontend/entrypoints/inertia.js
import { createInertiaApp } from '@inertiajs/svelte'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.svelte', { eager: true })
    return pages[`../pages/${name}.svelte`]
  },
  setup({ el, App, props }) {
    new App({ target: el, props })
  },
})
```

== Svelte 5

```js
// frontend/entrypoints/inertia.js
import { createInertiaApp } from '@inertiajs/svelte'
import { mount } from 'svelte'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.svelte', { eager: true })
    return pages[`../pages/${name}.svelte`]
  },
  setup({ el, App, props }) {
    mount(App, { target: el, props })
  },
})
```

:::

The `setup` callback receives everything necessary to initialize the client-side framework, including the root Inertia `App` component.

## Configuring defaults

@available_since core=2.2.11

You may pass a `defaults` object to `createInertiaApp()` to configure default settings for various features. You don't have to pass all keys, just the ones you want to tweak.

```js
createInertiaApp({
  // ...
  defaults: {
    form: {
      recentlySuccessfulDuration: 5000,
    },
    prefetch: {
      cacheFor: '1m',
      hoverDelay: 150,
    },
    visitOptions: (href, options) => {
      return {
        headers: {
          ...options.headers,
          'X-Custom-Header': 'value',
        },
      }
    },
  },
})
```

The `visitOptions` callback receives the target URL and the current visit options, and should return an object with any options you want to override. For more details on the available configuration options, see the [forms](/guide/forms#form-errors), [prefetching](/guide/prefetching), and [manual visits](/guide/manual-visits#global-visit-options) documentation.

### Updating at runtime

You may also update configuration values at runtime using the exported `config` instance. This is
particularly useful when you need to adjust settings based on user preferences or application state.

:::tabs key:frameworks
== Vue

```js
import { config } from '@inertiajs/vue3'

// Set a single value using dot notation...
config.set('form.recentlySuccessfulDuration', 1000)
config.set('prefetch.cacheFor', '5m')

// Set multiple values at once...
config.set({
  'form.recentlySuccessfulDuration': 1000,
  'prefetch.cacheFor': '5m',
})

// Get a configuration value...
const duration = config.get('form.recentlySuccessfulDuration')
```

== React

```js
import { config } from '@inertiajs/react'

// Set a single value using dot notation...
config.set('form.recentlySuccessfulDuration', 1000)
config.set('prefetch.cacheFor', '5m')

// Set multiple values at once...
config.set({
  'form.recentlySuccessfulDuration': 1000,
  'prefetch.cacheFor': '5m',
})

// Get a configuration value...
const duration = config.get('form.recentlySuccessfulDuration')
```

== Svelte 4|Svelte 5

```js
import { config } from '@inertiajs/svelte'

// Set a single value using dot notation...
config.set('form.recentlySuccessfulDuration', 1000)
config.set('prefetch.cacheFor', '5m')

// Set multiple values at once...
config.set({
  'form.recentlySuccessfulDuration': 1000,
  'prefetch.cacheFor': '5m',
})

// Get a configuration value...
const duration = config.get('form.recentlySuccessfulDuration')
```

:::

# Resolving components

The `resolve` callback tells Inertia how to load a page component. It receives a page name (string), and returns a page component module. How you implement this callback depends on which bundler (Vite or Webpack) you're using.

:::tabs key:frameworks
== Vue

```js
// Vite
// frontend/entrypoints/inertia.js
createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.vue', { eager: true })
    return pages[`../pages/${name}.vue`]
  },
  // ...
})

// Webpacker/Shakapacker
// javascript/packs/inertia.js
createInertiaApp({
  resolve: (name) => require(`../pages/${name}`),
  // ...
})
```

== React

```js
// Vite
// frontend/entrypoints/inertia.js
createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.jsx', { eager: true })
    return pages[`../pages/${name}.jsx`]
  },
  //...
})

// Webpacker/Shakapacker
// javascript/packs/inertia.js
createInertiaApp({
  resolve: (name) => require(`../pages/${name}`),
  //...
})
```

== Svelte 4|Svelte 5

```js
// Vite
// frontend/entrypoints/inertia.js
createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.svelte', { eager: true })
    return pages[`../pages/${name}.svelte`]
  },
  //...
})

// Webpacker/Shakapacker
// javascript/packs/inertia.js
createInertiaApp({
  resolve: (name) => require(`../pages/${name}.svelte`),
  //...
})
```

:::

By default we recommend eager loading your components, which will result in a single JavaScript bundle. However, if you'd like to lazy-load your components, see our [code splitting](/guide/code-splitting.md) documentation.

## Defining a root element

By default, Inertia assumes that your application's root template has a root element with an `id` of `app`. If your application's root element has a different `id`, you can provide it using the `id` property.

```js
createInertiaApp({
  id: 'my-app',
  // ...
})
```

> [!NOTE]
> Make sure the [`root_dom_id`](/guide/configuration#root_dom_id) configuration option matches the `id` property in your client-side setup.

## Script Element for Page Data

By default, Inertia stores the initial page data in a `data-page` attribute on the root element. You may configure Inertia to use a `<script type="application/json">` element instead, which is slightly faster and easier to inspect in your browser's dev tools.

```js
createInertiaApp({
  // ...
  defaults: {
    future: {
      useScriptElementForInitialPage: true,
    },
  },
})
```

You should also set the [`use_script_element_for_initial_page`](/guide/configuration#use_script_element_for_initial_page) config option to `true`.

> [!NOTE]
> Be sure to also update your [SSR entry point](/guide/server-side-rendering#add-server-entry-point) if you're using server-side rendering.
