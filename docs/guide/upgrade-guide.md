# Upgrade guide for v2.0

> [!NOTE]
> Inertia.js v2.0 is still in beta and these docs are a work-in-progress. Please report bugs on
> https://github.com/inertiajs/inertia and https://github.com/inertiajs/inertia-rails

## What's new

Inertia.js v2.0 is a huge step forward for Inertia! The core library has been completely rewritten to architecturally support asynchronous requests, enabling a whole set of new features, including:

- [Polling](/guide/polling)
- [Prefetching](/guide/prefetching)
- [Deferred props](/guide/deferred-props)
- [Infinite scrolling](/guide/merging-props)
- [Lazy loading data on scroll](/guide/load-when-visible)

Additionally, for security sensitive projects, Inertia now offers a [history encryption API](/guide/history-encryption), allowing you to clear page data from history state when logging out of an application.

## Upgrade dependencies

To upgrade to the Inertia.js v2.0 beta, first use npm to install the client-side adapter of your choice:

:::tabs key:frameworks
== Vue

```vue
npm install @inertiajs/vue3@next
```

== React

```jsx
npm install @inertiajs/react@next
```

== Svelte 4|Svelte 5

```svelte
npm install @inertiajs/svelte@next
```

:::

Next, upgrade the `inertia-rails` gem to use the `v2` dev branch:

```ruby
gem 'inertia_rails', github: 'inertiajs/inertia-rails', branch: 'v2'
```

## Breaking changes

While a significant release, Inertia.js v2.0 doesn't introduce many breaking changes. Here's a list of all the breaking changes:

### Dropped Vue 2 support

The Vue 2 adapter has been removed. Vue 2 reached End of Life on December 3, 2023, so this felt like it was time.

### Svelte adapter

- Dropped support for Svelte 3 as it reached End of Life on June 20, 2023.
- The `remember` helper has been renamed to `useRemember` to be consistent with other helpers.
- Updated `setup` callback in `inertia.js`. You need to pass `props` when initializing the `App` component. [See the updated guide](/guide/client-side-setup#initialize-the-inertia-app)
- The `setup` callback is now required in `ssr.js`. [See the updated guide](/guide/server-side-rendering#add-server-entry-point)

### Partial reloads are now async

Previously partial reloads in Inertia were synchronous, just like all Inertia requests. In v2.0, partial reloads are now asynchronous. Generally this is desirable, but if you were relying on these requests being synchronous, you may need to adjust your code.
