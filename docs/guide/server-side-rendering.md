# Server-Side Rendering (SSR)

Server-side rendering pre-renders your JavaScript pages on the server, allowing your visitors to receive fully rendered HTML when they visit your application. Since fully rendered HTML is served by your application, it's also easier for search engines to index your site.

Server-side rendering uses Node.js to render your pages in a background process; therefore, Node must be available on your server for server-side rendering to function properly.

## Vite Plugin Setup

@available_since rails=3.19.0 core=3.0.0

The recommended way to configure SSR is with the `@inertiajs/vite` plugin. This approach handles SSR configuration automatically, including development mode SSR without a separate Node.js server.

### 1. Install the Vite plugin

```bash
npm install @inertiajs/vite
```

### 2. Configure Vite

Add the Inertia plugin to your `vite.config.js` file. And configure entry point.

```js
// vite.config.js
import inertia from '@inertiajs/vite'

export default defineConfig({
  plugins: [
    // ...
    inertia({
      entry: 'entrypoints/inertia.js',
    }),
  ],
})
```

You may also configure SSR options explicitly.

```js
// vite.config.js
inertia({
  ssr: {
    entry: 'ssr/ssr.js',
    port: 13714,
    cluster: true,
  },
})
```

You may pass `false` to opt out of the plugin's automatic SSR handling, for example if you prefer to [configure SSR manually](#manual-setup) but still want to use the other features of the Vite plugin.

```js
// vite.config.js
inertia({
  ssr: false,
})
```

### 3. Update your build script

Update the `build` script in your `package.json` to build both bundles.

```json
{
  "scripts": {
      "dev": "vite",
     "build": "vite build" // [!code --]
     "build": "vite build && vite build --ssr" // [!code ++]
  }
}
```

### Development Mode

The Vite plugin handles SSR automatically during development. There is no need to build your SSR bundle or start a separate Node.js server. Simply run your dev servers as usual:

```bash
bin/dev
```

The Vite plugin exposes a server endpoint that Rails uses for rendering, complete with HMR support.

> [!NOTE]
> The `vite build --ssr`, `bin/vite ssr`, etc. commands are for [production](#production) only. You should not run them during development.

### Production

For production, build both bundles and start the SSR server.

```bash
npm run build
node public/assets-ssr/inertia.js
```

### Custom SSR Entry Point

The Vite plugin reuses your `inertia.js` entry point for both browser and SSR rendering by default, so no separate file is needed. The plugin detects the `data-server-rendered` attribute to decide whether to hydrate or mount, and the `setup` and `resolve` callbacks are optional.

If you need custom SSR logic (such as Vue plugins that should only run on the server), you may create a separate `entrypoints/ssr.js` file.

:::tabs key:frameworks

== Vue

```js
import createServer from '@inertiajs/vue3/server'

createServer((page) =>
  createInertiaApp({
    page,
    render: renderToString,
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.vue')
      return pages[`../pages/${name}.vue`]()
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

```jsx
import createServer from '@inertiajs/react/server'
import ReactDOMServer from 'react-dom/server'

createServer((page) =>
  createInertiaApp({
    page,
    render: ReactDOMServer.renderToString,
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.jsx')
      return pages[`../pages/${name}.jsx`]()
    },
    setup: ({ App, props }) => <App {...props} />,
  }),
)
```

== Svelte

```js
import createServer from '@inertiajs/svelte/server'

createServer((page) =>
  createInertiaApp({
    page,
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.svelte')
      return pages[`../pages/${name}.svelte`]()
    },
    setup({ App, props }) {
      return render(App, { props })
    },
  }),
)
```

:::

Be sure to add anything that's missing from your `inertia.js` file that makes sense to run in SSR mode, such as plugins or custom mixins.

## Manual Setup

If you prefer not to use the Vite plugin, you may configure SSR manually.

### 1. Create an SSR entry point

Create an SSR entry point file within your Laravel project.

:::tabs key:frameworks
== Vue

```bash
touch app/frontend/ssr/ssr.js
```

== React

```bash
touch app/frontend/ssr/ssr.jsx
```

== Svelte

```bash
touch app/frontend/ssr/ssr.js
```

:::

This file will look similar to your app entry point, but it runs in Node.js instead of the browser. Here's a complete example.

:::tabs key:frameworks

== Vue

```js
import createServer from '@inertiajs/vue3/server'

createServer((page) =>
  createInertiaApp({
    page,
    render: renderToString,
    resolve: (name) => {
      const pages = import.meta.glob('../pges/**/*.vue')
      return pages[`../pages/${name}.vue`]()
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

```jsx
import createServer from '@inertiajs/react/server'
import ReactDOMServer from 'react-dom/server'

createServer((page) =>
  createInertiaApp({
    page,
    render: ReactDOMServer.renderToString,
    resolve: (name) => {
      const pages = import.meta.glob('../pges/**/*.jsx')
      return pages[`../pages/${name}.jsx`]()
    },
    setup: ({ App, props }) => <App {...props} />,
  }),
)
```

== Svelte

```js
import createServer from '@inertiajs/svelte/server'

createServer((page) =>
  createInertiaApp({
    page,
    resolve: (name) => {
      const pages = import.meta.glob('../pges/**/*.svelte')
      return pages[`../pages/${name}.svelte`]()
    },
    setup({ App, props }) {
      return render(App, { props })
    },
  }),
)
```

:::

### 2. Configure Vite

Next, we need to update our Vite configuration to build our new `ssr.js` file. We can do this by adding a `ssrBuildEnabled` property to Ruby Vite plugin configuration in the `config/vite.json` file.

```json
"production": {
  "ssrBuildEnabled": true
}
```

### 3. Enable SSR in the Inertia's Rails adapter

Update Inertia Rails adapter cinfig to turn SSR on.

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.ssr_enabled = ViteRuby.config.ssr_build_enabled
end
```

### Clustering

By default, the SSR server runs on a single thread. You may enable clustering to start multiple Node servers on the same port, with requests handled by each thread in a round-robin fashion.

```js
// vite.config.js
inertia({
  ssr: {
    cluster: true,
  },
})
```

When using a [custom SSR entry point](#custom-ssr-entry-point) or [manual setup](#manual-setup), you may pass the `cluster` option to `createServer` instead.

@available_since core=2.0.7

:::tabs key:frameworks

== Vue

```js
createServer(
  (page) =>
    createInertiaApp({
      // ...
    }),
  { cluster: true },
)
```

== React

```jsx
createServer(
  (page) =>
    createInertiaApp({
      // ...
    }),
  { cluster: true },
)
```

== Svelte

```js
createServer(
  (page) =>
    createInertiaApp({
      // ...
    }),
  { cluster: true },
)
```

:::

## Running the SSR Server

> [!NOTE]
> The SSR server is only required in production. During development, the [Vite plugin](#development-mode) handles SSR automatically.

Once you have built both your client-side and server-side bundles, you may start the SSR server using the following command.

```bash
bin/vite ssr
```

With the server running, you should be able to access your app within the browser with server-side rendering enabled. In fact, you should be able to disable JavaScript entirely and still navigate around your application.

## Client-Side Hydration

You should also update your `inertia.js` file to use hydration instead of normal rendering. This allows <Vue>Vue</Vue><React>React</React><Svelte>Svelte</Svelte> to pick up the server-rendered HTML and make it interactive without re-rendering it.

:::tabs key:frameworks

== Vue

```js
import { createApp, h } from 'vue' // [!code --]
import { createSSRApp, h } from 'vue' // [!code ++]

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.vue')
    return pages[`../pages/${name}.vue`]()
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
import { createRoot } from 'react-dom/client' // [!code --]
import { hydrateRoot } from 'react-dom/client' // [!code ++]

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.jsx')
    return pages[`../pages/${name}.jsx`]()
  },
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />) // [!code --]
    hydrateRoot(el, <App {...props} />) // [!code ++]
  },
})
```

== Svelte

```js
import { mount } from 'svelte' // [!code --]
import { hydrate, mount } from 'svelte' // [!code ++]

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.svelte')
    return pages[`../pages/${name}.svelte`]()
  },
  setup({ el, App, props }) {
    mount(App, { target: el, props }) // [!code --]
    if (el.dataset.serverRendered === 'true') {
      // [!code ++:5]
      hydrate(App, { target: el, props })
    } else {
      mount(App, { target: el, props })
    }
  },
})
```

:::

## Error Handling

When SSR rendering fails, Inertia gracefully falls back to client-side rendering. The Vite plugin logs detailed error information to the console, including the component name, request URL, source location, and a tailored hint to help you resolve the issue.

Common SSR errors are automatically classified. Browser API errors (such as referencing `window` or `document` in server-rendered code) include guidance on moving the code to a lifecycle hook. Component resolution errors suggest checking file paths and casing.

The Rails adapter automatically logs SSR failures to `Rails.logger` at the `error` level. To customize error handling, set the `on_ssr_error` option in your `config/initializers/inertia_rails.rb` file.

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.on_ssr_error = ->(error, page) do
    Rails.logger.warn("SSR failed for #{page[:component]}: #{error.message}")
    Sentry.capture_exception(error) # or any error tracker
  end
end
```

The callback receives an `InertiaRails::SSRError` and the page hash, giving you access to the component name, props, and URL that failed.

### Raising on Error

For CI or E2E testing, you may prefer SSR failures to raise an exception instead of falling back silently. Set the `ssr_raise_on_error` option in your initializer.

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.ssr_raise_on_error = true
end
```

## Disabling SSR

Sometimes you may wish to disable server-side rendering for certain controllers or pages in your application. You may do so by setting the `ssr_enabled` option to `false` using `inertia_config`.

```ruby
class AdminController < ApplicationController
  inertia_config(ssr_enabled: false)
end
```

You can also use a lambda for conditional SSR, which is evaluated per-request in the controller context:

```ruby
class DashboardController < ApplicationController
  inertia_config(ssr_enabled: -> { !complex_client_only_page? })
end
```

## Deployment

When deploying your SSR enabled app to production, you'll need to build both the client-side (`application.js`) and server-side bundles (`ssr.js`), and then run the SSR server as a background process.
