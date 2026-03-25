# Instant Visits

@available_since core=3.0.0

Sometimes you may wish to navigate to a new page without waiting for the server to respond. Instant visits allow Inertia to immediately swap to the target page component while the server request happens in the background. Once the server responds, the real props are merged in.

Unlike [client-side visits](/guide/manual-visits#client-side-visits), which update the page entirely on the client without making a server request, instant visits still make a full server request. The difference is that the user sees the target page right away instead of waiting for the response.

## Basic Usage

To make an instant visit, provide the target `component` name to a `Link` or to `router.visit()`.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/dashboard" component="Dashboard">Dashboard</Link>
</template>
```

== React

```jsx
import { Link } from '@inertiajs/react'

export default () => (
  <Link href="/dashboard" component="Dashboard">
    Dashboard
  </Link>
)
```

== Svelte

```svelte
<script>
  import { inertia, Link } from '@inertiajs/svelte'
</script>

<a href="/dashboard" use:inertia={{ component: 'Dashboard' }}>Dashboard</a>

<Link href="/dashboard" component="Dashboard">Dashboard</Link>
```

:::

When clicked, Inertia immediately renders the `Dashboard` component while the server request fires in the background. The full props are merged in when the response arrives.

The target component must be able to render without its page-specific props, as only [shared props](/guide/shared-data) are available on the intermediate page. You may use optional chaining or conditional rendering to handle missing props.

Programmatic instant visits work the same way via the `component` option on `router.visit()`.

```js
router.visit('/dashboard', {
  component: 'Dashboard',
})
```

## Shared Props

The Rails adapter includes a `sharedProps` metadata key in the page response, listing the top-level prop keys registered via `shared_props`.

```json lines
{
  "component": "Dashboard",
  "props": {
    "auth": { "user": "..." },
    "stats": {
      /*...*/
    }
  },
  "sharedProps": ["auth"]
}
```

Inertia reads this list and carries those props over from the current page to the intermediate page. Props like `auth` are available immediately, while page-specific props like `stats` will be `undefined` until the server responds.

## Page Props

You may provide props for the intermediate page using the `pageProps` option. This is useful for passing data you already have on the current page, or for setting placeholder values to display loading states while the server responds.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link
    href="/posts/1"
    component="Posts/Show"
    :page-props="{ title: 'Loading...' }"
  >
    View Post
  </Link>
</template>
```

== React

```jsx
import { Link } from '@inertiajs/react'

export default () => (
  <Link
    href="/posts/1"
    component="Posts/Show"
    pageProps={{ title: 'Loading...' }}
  >
    View Post
  </Link>
)
```

== Svelte

```svelte
<script>
  import { Link } from '@inertiajs/svelte'
</script>

<Link
  href="/posts/1"
  component="Posts/Show"
  pageProps={{ title: 'Loading...' }}
>
  View Post
</Link>
```

:::

When `pageProps` is provided as an object, shared props are not automatically carried over. You are in full control of the intermediate page's props.

A callback may also be passed to `pageProps`. The callback receives the current page's props and the shared props as arguments, so you may selectively spread them.

```js
router.visit('/posts/1', {
  component: 'Posts/Show',
  pageProps: (currentProps, sharedProps) => ({
    ...sharedProps,
    title: 'Loading...',
  }),
})
```

## Disabling Shared Prop Keys

You may disable the `sharedProps` metadata key in your configuration. The server will still resolve and include shared prop values in the response, but the metadata listing which keys are shared will be omitted. Without this list, the client cannot identify which props to carry over during instant visits.

```ruby
# config/initializers/inertia.rb

InertiaRails.configure do |config|
  config.expose_shared_prop_keys = false
end
```
