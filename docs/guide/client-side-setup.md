# Client-Side Setup

Once you have your [server-side framework configured](/guide/server-side-setup), you then need to setup your client-side framework. Inertia currently provides support for React, Vue, and Svelte.

## Prerequisites

> [!NOTE]
> You can skip this step if you have already executed the [Rails generator](/guide/server-side-setup#rails-generator).

Inertia requires your client-side framework and its corresponding Vite plugin to be installed and configured. You may skip this section if your application already has these set up.

:::tabs key:frameworks

== Vue

```bash
npm install vue @vitejs/plugin-vue
```

== React

```bash
npm install react react-dom @vitejs/plugin-react
```

== Svelte

```bash
npm install svelte @sveltejs/vite-plugin-svelte
```

:::

Then, add the framework plugin to your `vite.config.js` file.

:::tabs key:frameworks

== Vue

```js
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [RubyPlugin(), vue()],
})
```

== React

```js
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [RubyPlugin(), react()],
})
```

== Svelte

```js
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { svelte } from '@sveltejs/vite-plugin-svelte'

export default defineConfig({
  plugins: [RubyPlugin(), svelte()],
})
```

:::

For more information on configuring these plugins, consult [Vite Rails documentation](https://vite-ruby.netlify.app).

## Installation

> [!NOTE]
> You can skip this step if you have already executed the [Rails generator](/guide/server-side-setup#rails-generator).

### Install dependencies

@available_since core=3.0.0

Install the Inertia client-side adapter and Vite plugin.

:::tabs key:frameworks

== Vue

```bash
npm install @inertiajs/vue3 @inertiajs/vite
```

== React

```bash
npm install @inertiajs/react @inertiajs/vite
```

== Svelte

```bash
npm install @inertiajs/svelte @inertiajs/vite
```

:::

### Configure Vite

@available_since core=3.0.0

Add the Inertia plugin to your `vite.config.js` file.

```js
import inertia from '@inertiajs/vite'
import RubyPlugin from 'vite-plugin-ruby'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    inertia(),
    // ...
  ],
})
```

### Initialize the Inertia app

Update your main JavaScript file to boot your Inertia app. The Vite plugin handles page resolution and mounting automatically, so a minimal entry point is all you need.

:::tabs key:frameworks

== Vue

```js
import { createInertiaApp } from '@inertiajs/vue3'

createInertiaApp()
```

== React

```js
import { createInertiaApp } from '@inertiajs/react'

createInertiaApp()
```

== Svelte

```js
import { createInertiaApp } from '@inertiajs/svelte'

createInertiaApp()
```

:::

The plugin generates a default resolver that looks for pages in both `./pages` and `./Pages` directories, and the app mounts automatically.

### React Strict Mode

@available_since core=3.0.0

The React adapter supports enabling React's [Strict Mode](https://react.dev/reference/react/StrictMode) via the `strictMode` option.

```jsx
createInertiaApp({
  strictMode: true,
  // ...
})
```

### Pages Shorthand

@available_since core=3.0.0

You may use the `pages` shorthand to customize which directory to search for page components.

:::tabs key:frameworks

== Vue

```js
import { createInertiaApp } from '@inertiajs/vue3'

createInertiaApp({
  pages: './AppPages',
  // ...
})
```

== React

```js
import { createInertiaApp } from '@inertiajs/react'

createInertiaApp({
  pages: './AppPages',
  // ...
})
```

== Svelte

```js
import { createInertiaApp } from '@inertiajs/svelte'

createInertiaApp({
  pages: './AppPages',
  // ...
})
```

:::

An object may also be provided for more control over how pages are resolved.

```js
createInertiaApp({
  pages: {
    path: './Pages',
    extension: '.tsx',
    lazy: true,
    transform: (name, page) => name.replace('/', '-'),
  },
})
```

| Option      | Description                                                                                                          |
| ----------- | -------------------------------------------------------------------------------------------------------------------- |
| `path`      | The directory to search for page components.                                                                         |
| `extension` | A string or array of file extensions (e.g., `'.tsx'` or `['.tsx', '.jsx']`). Defaults to your framework's extension. |
| `lazy`      | Whether to lazy-load page components. Defaults to `true`. See [code splitting](/guide/code-splitting).               |
| `transform` | A callback that receives the page name and page object, returning a transformed name.                                |

## Manual Setup

If you prefer not to use the Vite plugin, you may provide the `resolve` and `setup` callbacks manually. The `resolve` callback tells Inertia how to load a page component and receives the component name and the full [page object](/guide/the-protocol). The `setup` callback initializes the client-side framework.

:::tabs key:frameworks

== Vue

```js
import { createApp, h } from 'vue'
import { createInertiaApp } from '@inertiajs/vue3'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.vue')
    return pages[`../pages/${name}.vue`]()
  },
  setup({ el, App, props, plugin }) {
    createApp({ render: () => h(App, props) })
      .use(plugin)
      .mount(el)
  },
})
```

== React

```jsx
import { createInertiaApp } from '@inertiajs/react'
import { createRoot } from 'react-dom/client'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.jsx')
    return pages[`../pages/${name}.jsx`]()
  },
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />)
  },
})
```

== Svelte

```js
import { createInertiaApp } from '@inertiajs/svelte'
import { mount } from 'svelte'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.svelte')
    return pages[`../pages/${name}.svelte`]()
  },
  setup({ el, App, props }) {
    mount(App, { target: el, props })
  },
})
```

:::

By default, page components are lazy-loaded, splitting each page into its own bundle. To eagerly bundle all pages into a single file instead, see the [code splitting](/guide/code-splitting) documentation.

## Configuring Defaults

@available_since core=2.2.11

You may pass a `defaults` object to `createInertiaApp()` to configure default settings for various features. You don't have to pass a default for every key, just the ones you want to tweak.

```js
createInertiaApp({
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
  // ...
})
```

The `visitOptions` callback receives the target URL and the current visit options, and should return an object with any options you want to override. For more details on the available configuration options, see the [forms](/guide/forms#form-errors), [prefetching](/guide/prefetching), and [manual visits](/guide/manual-visits#global-visit-options) documentation.

### Updating Configuration at Runtime

You may also update configuration values at runtime using the exported `config` instance. This is particularly useful when you need to adjust settings based on user preferences or application state.

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

== Svelte

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

## Defining a Root Element

By default, Inertia assumes that your application's root template has a root element with an `id` of `app`. If your application's root element has a different `id`, you can provide it using the `id` property.

```js
createInertiaApp({
  id: 'my-app',
  // ...
})
```

If you change the `id` of the root element, be sure to update it [server-side](/guide/server-side-setup#root-template) as well.

## HTTP Client

@available_since core=3.0.0

Unlike Inertia 2 and earlier, Inertia 3 uses a built-in XHR client for all requests. No additional HTTP libraries like Axios are required.

### Using Axios

You may provide the `axiosAdapter` as the `http` option when creating your Inertia app. This is useful when your application requires a custom Axios instance.

```js
import { axiosAdapter } from '@inertiajs/core'

createInertiaApp({
  http: axiosAdapter(),
  // ...
})
```

A custom Axios instance may also be provided to the adapter.

```js
import axios from 'axios'
import { axiosAdapter } from '@inertiajs/core'

const instance = axios.create({
  // ...
})

createInertiaApp({
  http: axiosAdapter(instance),
  // ...
})
```

### Interceptors

The built-in XHR client supports interceptors for modifying requests, inspecting responses, or handling errors. These interceptors apply to all HTTP requests made by Inertia, including those from the router, `useForm`, `<Form>`, and `useHttp`.

:::tabs key:frameworks

== Vue

```js
import { http } from '@inertiajs/vue3'

const removeRequestHandler = http.onRequest((config) => {
  config.headers['X-Custom-Header'] = 'value'
  return config
})

const removeResponseHandler = http.onResponse((response) => {
  console.log('Response status:', response.status)
  return response
})

const removeErrorHandler = http.onError((error) => {
  console.error('Request failed:', error)
})

// Remove a handler when it's no longer needed...
removeRequestHandler()
```

== React

```js
import { http } from '@inertiajs/react'

const removeRequestHandler = http.onRequest((config) => {
  config.headers['X-Custom-Header'] = 'value'
  return config
})

const removeResponseHandler = http.onResponse((response) => {
  console.log('Response status:', response.status)
  return response
})

const removeErrorHandler = http.onError((error) => {
  console.error('Request failed:', error)
})

// Remove a handler when it's no longer needed...
removeRequestHandler()
```

== Svelte

```js
import { http } from '@inertiajs/svelte'

const removeRequestHandler = http.onRequest((config) => {
  config.headers['X-Custom-Header'] = 'value'
  return config
})

const removeResponseHandler = http.onResponse((response) => {
  console.log('Response status:', response.status)
  return response
})

const removeErrorHandler = http.onError((error) => {
  console.error('Request failed:', error)
})

// Remove a handler when it's no longer needed...
removeRequestHandler()
```

:::

Each `on*` method returns a cleanup function that removes the handler when called. Request handlers receive the request config and must return it (modified or not). Response handlers receive the response and must also return it. Handlers may be asynchronous.

### Custom HTTP Client

For full control over how requests are made, you may provide a completely custom HTTP client via the `http` option. A custom client must implement the `request` method, which receives an `HttpRequestConfig` and returns a promise resolving to an `HttpResponse`. Review the [xhrHttpClient.ts](https://github.com/inertiajs/inertia/blob/3.x/packages/core/src/xhrHttpClient.ts) source for a reference implementation.
