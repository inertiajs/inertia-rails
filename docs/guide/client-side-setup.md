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
    const pages = import.meta.glob('./Pages/**/*.svelte', { eager: true })
    return pages[`./Pages/${name}.svelte`]
  },
  setup({ el, App, props }) {
    mount(App, { target: el, props })
  },
})
```

:::

The `setup` callback receives everything necessary to initialize the client-side framework, including the root Inertia `App` component.

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
