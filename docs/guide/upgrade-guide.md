# Upgrade Guide for v3.0

## What's New

Inertia.js v3.0 is a major release focused on simplicity and developer experience. Axios has been replaced with a
built-in XHR client for a smaller bundle, SSR now works out of the box during development without a separate Node.js
server, and the new `@inertiajs/vite` plugin handles page resolution and SSR configuration automatically. This release
also introduces standalone HTTP requests via the `useHttp` hook, optimistic updates with automatic rollback, layout
props for sharing data between pages and layouts, and improved exception handling.

- [Vite Plugin](/guide/client-side-setup#installation) — Automatic page resolution, SSR setup, and optional
  setup/resolve callbacks.
- [HTTP Requests](/guide/http-requests) — Make standalone HTTP requests with the useHttp hook, without triggering page
  visits.
- [Optimistic Updates](/guide/optimistic-updates) — Apply data changes instantly before the server responds, with
  automatic rollback on failure.
- [Layout Props](/guide/layouts#layout-props) — Share dynamic data between pages and persistent layouts with the
  useLayoutProps hook.
- [Simplified SSR](/guide/server-side-rendering) — SSR works automatically in Vite dev mode. No separate Node.js server
  needed.
- [Exception Handling](/guide/error-handling#production) — Render custom Inertia error pages directly from your
  exception handler, with shared data.

This release also includes several additional improvements:

- [Instant visits](/guide/instant-visits) that swap to the target component before the server responds
- [Form component generics](/guide/typescript#form-component) for type-safe errors and slot props
- [Disable SSR per-route](/guide/server-side-rendering#disabling-ssr) via middleware or facade
- [Improved SSR error messages](/guide/server-side-rendering#error-handling) with component names, URLs, and actionable
  hints
- [Page object in resolve callback](/guide/client-side-setup#manual-setup) for context-aware component resolution
- [Built-in HTTP interceptors](/guide/client-side-setup#interceptors) without Axios
- [Default layout](/guide/layouts#default-layouts) option in `createInertiaApp`
- [`preserveErrors`](/guide/partial-reloads#preserving-errors) option to preserve validation errors during partial
  reloads

## Upgrade Dependencies

To upgrade to Inertia.js v3.0, first use npm to install the client-side adapter of your choice:

:::tabs key:frameworks

== Vue

```bash
npm install @inertiajs/vue3@^3.0
```

== React

```bash
npm install @inertiajs/react@^3.0
```

== Svelte

```bash
npm install @inertiajs/svelte@^3.0
```

:::

You may also install the new optional Vite plugin, which provides a simplified SSR setup and a `pages` shorthand for
component resolution:

```bash
npm install @inertiajs/vite@^3.0
```

Next, upgrade the `inertia_rails` gem:

```ruby
gem 'inertia_rails', '~> 3.19'
```

Make sure you are using configuration options that are compatible with Inertia.js v3.0.

```ruby
# config/initializers/inertia.rb
InertiaRails.configure do |config|
  config.use_script_element_for_initial_page = true
  config.use_data_inertia_head_attribute = true
  config.always_include_errors_hash = true
  # ...
end
```

## Breaking Changes

---

### Requirements

#### React 19+

The React adapter now requires React 19. React 18 and below are no longer supported.

#### Svelte 5+

The Svelte adapter now requires Svelte 5. Svelte 4 and below are no longer supported. All Svelte code should be updated
to use the Svelte 5 runes syntax (`$props()`, `$state()`, `$effect()`, etc).

### Axios Removed

Inertia no longer ships with or requires Axios. For most applications, this requires no changes. The built-in XHR client
supports [interceptors](/guide/client-side-setup#interceptors) as well, so Axios interceptors may be migrated directly.
You may also continue using Axios via the [Axios adapter](/guide/client-side-setup#using-axios), or provide a
fully [custom HTTP client](/guide/client-side-setup#custom-http-client).

### `qs` Dependency Removed

The `qs` package has been replaced with a built-in query string implementation and is no longer included as a dependency
of `@inertiajs/core`. Inertia's internal query string handling remains the same, but you should install `qs` directly if
your application imports it.

```bash
npm install qs
```

### `lodash-es` Dependency Removed

The `lodash-es` package has been replaced with `es-toolkit` and is no longer included as a dependency of `@inertiajs/core`. You should install `lodash-es` directly if your application imports it.

```bash
npm install lodash-es
```

### Event Renames

Two global events have been renamed for clarity:

| v2 Name     | v3 Name         | Document Event          |
| ----------- | --------------- | ----------------------- |
| `invalid`   | `httpException` | `inertia:httpException` |
| `exception` | `networkError`  | `inertia:networkError`  |

Global event listeners should be updated accordingly:

```js
// Before (v2)
router.on('invalid', (event) => { ...
})
router.on('exception', (event) => { ...
})

// After (v3)
router.on('httpException', (event) => { ...
})
router.on('networkError', (event) => { ...
})
```

You may also handle these events per-visit using the new `onHttpException` and `onNetworkError` callbacks:

```js
router.post('/users', data, {
  onHttpException: (response) => { ...
  },
  onNetworkError: (error) => { ...
  },
})
```

### `router.cancel()` Replaced

The `router.cancel()` method has been replaced by `router.cancelAll()`. In v2, `cancel()` only cancelled synchronous requests. The new `cancelAll()` method cancels all synchronous, asynchronous, and prefetch requests by default. You may pass options to limit which request types are cancelled.

```js
// Before (v2) — only cancelled sync requests
router.cancel()

// After (v3) — cancels all request types
router.cancelAll()

// To match v2 behavior (sync only)...
router.cancelAll({ async: false, prefetch: false })
```

See the [visit cancellation](/guide/manual-visits#visit-cancellation) documentation for more details.

### Future Options Removed

The `future` configuration namespace has been removed. All four future options from v2 are now always enabled and no
longer configurable:

- `future.preserveEqualProps`
- `future.useDataInertiaHeadAttribute`
- `future.useDialogForErrorModal`
- `future.useScriptElementForInitialPage`

```js
// Before (v2)
createInertiaApp({
  defaults: {
    future: {
      preserveEqualProps: true,
      useDataInertiaHeadAttribute: true,
      useDialogForErrorModal: true,
      useScriptElementForInitialPage: true,
    },
  },
})

// After (v3) - just remove the `future` block
createInertiaApp({
  // ...
})
```

Initial page data is now always passed via a `<script type="application/json">` element. The legacy `data-page`
attribute approach is no longer supported.

### Head Element Attributes

The `inertia` attribute used on elements in your root ERB template's `<head>` section has been renamed to `data-inertia`. You should update any head elements that use this attribute:

```html
<!-- Before (v2) -->
<title inertia>My Website</title>

<!-- After (v3) -->
<title data-inertia>My Website</title>
```

### Progress Indicator Exports Removed

The named exports `hideProgress()` and `revealProgress()` have been removed. If needed, use the `progress` object
directly:

```js
import { progress } from '@inertiajs/vue3'

progress.hide()
progress.reveal()
```

### Deferred Component Behavior (React)

The React `<Deferred>` component no longer resets to show the fallback during partial reloads. Previously, the fallback
was shown each time a partial reload was triggered. Now the existing content remains visible while new data loads,
consistent with the Vue and Svelte behavior.

A new `reloading` slot prop is available across all adapters, allowing you to show a loading indicator during partial
reloads while keeping the existing content visible. See the [deferred props](/guide/deferred-props#reloading)
documentation for details.

### Form Processing Reset Timing

The `useForm` helper now only resets `processing` and `progress` state in the `onFinish` callback, rather than
immediately upon receiving a response. This ensures the processing state remains `true` until the visit is fully
complete.

### Initializer Configuration

Make sure to set `use_script_element_for_initial_page` and `use_data_inertia_head_attribute` to `true` when upgrading frontend dependencies to Inertia 3.x:

```ruby
InertiaRails.configure do |config|
  config.use_data_inertia_head_attribute = true
  config.use_script_element_for_initial_page = true
end
```

## Other Changes

---

### SSR in Development

When using the new `@inertiajs/vite` plugin, SSR works automatically during development by simply running `bin/dev`. You
no longer need to build your SSR bundle with `bin/vite build --ssr` or start a separate Node.js server with
`bin/vite ssr` during development. These commands are now only required
for [production deployments](/guide/server-side-rendering#running-the-ssr-server).

### Nested Prop Types

Prop types like `InertiaRails.optional`, `InertiaRails.defer()`, and `InertiaRails.merge()` now work inside closures and
nested arrays. Inertia resolves them at any depth and uses dot-notation paths in partial reload metadata.

```ruby
class DashboardController < ApplicationController
  def index
    render inertia: {
      auth: -> {
        {
          user: Current.user,
          notifications: InertiaRails.defer { Current.user.unread_notifications },
          invoices: Inertia.optional { Current.user.invoices }
        }
      }
    }
  end
end
```

On the client side, the `only` and `except` options, as well as the `Deferred` and `WhenVisible` components, all support
dot-notation for targeting nested props.

```js
router.reload({ only: ['auth.notifications'] })
```

### ES2022 Build Target

Inertia packages now target ES2022, up from ES2020 in v2. You may use the [`@vitejs/plugin-legacy`](https://www.npmjs.com/package/@vitejs/plugin-legacy) Vite plugin if your application needs to support older browsers.

### ESM-Only Packages

All Inertia packages now ship as ES Modules only. CommonJS `require()` imports are no longer supported. You should
update any `require()` calls to use `import` statements instead.

### Page Object Changes

The `clearHistory` and `encryptHistory` properties in the [page object](/guide/the-protocol#the-page-object) are now
optional and only included in the response when `true`. Previously, every response included `"clearHistory": false` and
`"encryptHistory": false` even when history wasn't being cleared or encrypted.

## Upgrade guide for v2.0

### What's new

Inertia.js v2.0 is a huge step forward for Inertia! The core library has been completely rewritten to architecturally
support asynchronous requests, enabling a whole set of new features, including:

- [Polling](/guide/polling)
- [Prefetching](/guide/prefetching)
- [Deferred props](/guide/deferred-props)
- [Infinite scrolling](/guide/merging-props)
- [Lazy loading data on scroll](/guide/load-when-visible)

Additionally, for security sensitive projects, Inertia now offers a [history encryption API](/guide/history-encryption),
allowing you to clear page data from history state when logging out of an application.

### Upgrade dependencies

To upgrade to Inertia.js v2.0, first use npm to install the client-side adapter of your choice:

:::tabs key:frameworks
== Vue

```vue
npm install @inertiajs/vue3@^2.0
```

== React

```jsx
npm
install
@inertiajs/
react
@^
2.0
```

== Svelte

```svelte
npm install @inertiajs/svelte@^2.0
```

:::

Next, use at least the 3.6 version of `inertia-rails`.

```ruby
gem 'inertia_rails', '~> 3.6'
```

### Breaking changes

While a significant release, Inertia.js v2.0 doesn't introduce many breaking changes. Here's a list of all the breaking
changes:

#### Dropped Vue 2 support

The Vue 2 adapter has been removed. Vue 2 reached End of Life on December 3, 2023, so this felt like it was time.

#### Svelte adapter

- Dropped support for Svelte 3 as it reached End of Life on June 20, 2023.
- The `remember` helper has been renamed to `useRemember` to be consistent with other helpers.
- Updated `setup` callback in `inertia.js`. You need to pass `props` when initializing the `App`
  component. [See the updated guide](/guide/client-side-setup#initialize-the-inertia-app)
- The `setup` callback is now required in
  `ssr.js`. [See the updated guide](/guide/server-side-rendering#add-server-entry-point)

#### Partial reloads are now async

Previously partial reloads in Inertia were synchronous, just like all Inertia requests. In v2.0, partial reloads are now
asynchronous. Generally this is desirable, but if you were relying on these requests being synchronous, you may need to
adjust your code.
