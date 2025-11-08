# Server-side Rendering (SSR)

Server-side rendering pre-renders your JavaScript pages on the server, allowing your visitors to receive fully rendered HTML when they visit your application. Since fully rendered HTML is served by your application, it's also easier for search engines to index your site.

> [!NOTE]
> Server-side rendering uses Node.js to render your pages in a background process; therefore, Node must be available on your server for server-side rendering to function properly.

> [!NOTE]
> For Vue `< 3.2.13` you will need to install `@vue/server-renderer` as a dependency, and use it instead of `vue/server-renderer`.

## Add server entry-point

Next, we'll create a `app/frontend/ssr/ssr.js` file within the Rails project that will serve as the SSR entry point.

This file is going to look very similar to your regular inertia initialization file, except it's not going to run in the browser, but rather in Node.js. Here's a complete example.

:::tabs key:frameworks
== Vue

```js
import { createInertiaApp } from '@inertiajs/vue3'
import createServer from '@inertiajs/vue3/server'
import { renderToString } from 'vue/server-renderer'
import { createSSRApp, h } from 'vue'

createServer((page) =>
  createInertiaApp({
    page,
    render: renderToString,
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.vue', { eager: true })
      return pages[`../pages/${name}.vue`]
    },
    setup({ App, props, plugin }) {
      return createSSRApp({
        render: () => h(App, props),
      }).use(plugin)
    },
  }),
)
```

== React

```js
import { createInertiaApp } from '@inertiajs/react'
import createServer from '@inertiajs/react/server'
import ReactDOMServer from 'react-dom/server'

createServer((page) =>
  createInertiaApp({
    page,
    render: ReactDOMServer.renderToString,
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.jsx', { eager: true })
      return pages[`../pages/${name}.jsx`]
    },
    setup: ({ App, props }) => <App {...props} />,
  }),
)
```

== Svelte 4

```js
import { createInertiaApp } from '@inertiajs/svelte'
import createServer from '@inertiajs/svelte/server'

createServer((page) =>
  createInertiaApp({
    page,
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.svelte', { eager: true })
      return pages[`../pages/${name}.svelte`]
    },
    setup({ App, props }) {
      return App.render(props)
    },
  }),
)
```

== Svelte 5

```js
import { createInertiaApp } from '@inertiajs/svelte'
import createServer from '@inertiajs/svelte/server'
import { render } from 'svelte/server'

createServer((page) =>
  createInertiaApp({
    page,
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.svelte', { eager: true })
      return pages[`../pages/${name}.svelte`]
    },
    setup({ App, props }) {
      return render(App, { props })
    },
  }),
)
```

:::

When creating this file, be sure to add anything that's missing from your regular initialization file that makes sense to run in SSR mode, such as plugins or custom mixins.

## Clustering

> Requires `@inertiajs/core` v2.0.7 or higher.

By default, the SSR server will run on a single thread. Clustering starts multiple Node servers on the same port, requests are then handled by each thread in a round-robin way.

You can enable clustering by passing a second argument of options to `createServer`.

:::tabs key:frameworks
== Vue

```js
import { createInertiaApp } from '@inertiajs/vue3'
import createServer from '@inertiajs/vue3/server'
import { renderToString } from 'vue/server-renderer'
import { createSSRApp, h } from 'vue'

createServer(
  (page) =>
    createInertiaApp({
      // ...
    }),
  { cluster: true },
)
```

== React

```js
import { createInertiaApp } from '@inertiajs/react'
import createServer from '@inertiajs/react/server'
import ReactDOMServer from 'react-dom/server'

createServer(
  (page) =>
    createInertiaApp({
      // ...
    }),
  { cluster: true },
)
```

== Svelte 4

```js
import { createInertiaApp } from '@inertiajs/svelte'
import createServer from '@inertiajs/svelte/server'

createServer(
  (page) =>
    createInertiaApp({
      // ...
    }),
  { cluster: true },
)
```

== Svelte 5

```js
import { createInertiaApp } from '@inertiajs/svelte'
import createServer from '@inertiajs/svelte/server'
import { render } from 'svelte/server'

createServer(
  (page) =>
    createInertiaApp({
      // ...
    }),
  { cluster: true },
)
```

:::

## Setup Vite Ruby

Next, we need to update our Vite configuration to build our new `ssr.js` file. We can do this by adding a `ssrBuildEnabled` property to Ruby Vite plugin configuration in the `config/vite.json` file.

```json
  "production": {
    "ssrBuildEnabled": true // [!code ++]
  }
```

> [!NOTE]
> For more available properties see the [Ruby Vite documentation](https://vite-ruby.netlify.app/config/#ssr-options-experimental).

## Enable SSR in the Inertia's Rails adapter

```ruby
InertiaRails.configure do |config|
  config.ssr_enabled = ViteRuby.config.ssr_build_enabled
end
```

Now you can build your server-side bundle.

```shell
bin/vite build --ssr
```

## Running the SSR server

Now that you have built both your client-side and server-side bundles, you should be able run the Node-based Inertia SSR server using the following command.

```shell
bin/vite ssr
```

With the server running, you should be able to access your app within the browser with server-side rendering enabled. In fact, you should be able to disable JavaScript entirely and still navigate around your application.

## Client side hydration

Since your website is now being server-side rendered, you can instruct your client to "hydrate" the static markup and make it interactive instead of re-rendering all the HTML that we just generated.

To enable client-side hydration, update your initialization file.

:::tabs key:frameworks
== Vue

```js
// frontend/entrypoints/inertia.js
import { createApp, h } from 'vue' // [!code --]
import { createSSRApp, h } from 'vue' // [!code ++]
import { createInertiaApp } from '@inertiajs/vue3'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.vue', { eager: true })
    return pages[`../pages/${name}.vue`]
  },
  setup({ el, App, props, plugin }) {
    createApp({ render: () => h(App, props) }) // [!code --]
    createSSRApp({ render: () => h(App, props) }) // [!code ++]
      .use(plugin)
      .mount(el)
  },
})
```

== React

```js
// frontend/entrypoints/inertia.js
import { createInertiaApp } from '@inertiajs/react'
import { createRoot } from 'react-dom/client' // [!code --]
import { hydrateRoot } from 'react-dom/client' // [!code ++]

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.jsx', { eager: true })
    return pages[`../pages/${name}.jsx`]
  },
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />) // [!code --]
    hydrateRoot(el, <App {...props} />) // [!code ++]
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
    new App({ target: el, props }) // [!code --]
    new App({ target: el, props, hydrate: true }) // [!code ++]
  },
})
```

You will also need to set the `hydratable` compiler option to `true` in your `vite.config.js` file.

<!-- prettier-ignore -->
```js
// vite.config.js
import { svelte } from '@sveltejs/vite-plugin-svelte'
import laravel from 'laravel-vite-plugin'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [
    laravel.default({
      input: ['resources/css/app.css', 'resources/js/app.js'],
      ssr: 'resources/js/ssr.js',
      refresh: true,
    }),
    svelte(), // [!code --]
    svelte({ // [!code ++]
      // [!code ++]
      compilerOptions: { // [!code ++]
        // [!code ++]
        hydratable: true, // [!code ++]
      }, // [!code ++]
    }), // [!code ++]
  ],
})
```

== Svelte 5

<!-- prettier-ignore -->
```js
// frontend/entrypoints/inertia.js
import { createInertiaApp } from '@inertiajs/svelte'
import { mount } from 'svelte' // [!code --]
import { hydrate, mount } from 'svelte' // [!code ++]

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('./Pages/**/*.svelte', { eager: true })
    return pages[`./Pages/${name}.svelte`]
  },
  setup({ el, App, props }) {
    mount(App, { target: el, props }) // [!code --]
    if (el.dataset.serverRendered === 'true') { // [!code ++]
      hydrate(App, { target: el, props }) // [!code ++]
    } else { // [!code ++]
      mount(App, { target: el, props }) // [!code ++]
    } // [!code ++]
  },
})
```

:::

## Deployment

When deploying your SSR enabled app to production, you'll need to build both the client-side (`application.js`) and server-side bundles (`ssr.js`), and then run the SSR server as a background process.
