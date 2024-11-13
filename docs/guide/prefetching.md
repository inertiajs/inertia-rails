# Prefetching

Inertia supports prefetching data for pages that are likely to be visited next. This can be useful for improving the perceived performance of your app by allowing the data to be fetched in the background while the user is still interacting with the current page.

## Link prefetching

To prefetch data for a page, you can use the `prefetch` method on the Inertia link component. By default, Inertia will prefetch the data for the page when the user hovers over the link after more than 75ms.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/users" prefetch>Users</Link>
</template>
```

== React

```jsx
import { Link } from '@inertiajs/react'

export default () => (
  <Link href="/users" prefetch>
    Users
  </Link>
)
```

== Svelte 4|Svelte 5

```svelte
<script>
  import { inertia } from '@inertiajs/svelte'
</script>

<a href="/users" use:inertia={{ prefetch: true }}>Users</a>
```

:::

By default, data is cached for 30 seconds before being evicted. You can customize this behavior by passing a `cacheFor` prop to the `Link` component.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/users" prefetch cache-for="1m">Users</Link>
  <Link href="/users" prefetch cache-for="10s">Users</Link>
  <Link href="/users" prefetch :cache-for="5000">Users</Link>
</template>
```

== React

```jsx
import { Link } from '@inertiajs/react'

export default () => (
  <>
    <Link href="/users" prefetch cacheFor="1m">
      Users
    </Link>
    <Link href="/users" prefetch cacheFor="10s">
      Users
    </Link>
    <Link href="/users" prefetch cacheFor={5000}>
      Users
    </Link>
  </>
)
```

== Svelte 4|Svelte 5

```svelte
<script>
  import { inertia } from '@inertiajs/svelte'
</script>

<a href="/users" use:inertia={{ prefetch: true, cacheFor: '1m' }}>Users</a>
<a href="/users" use:inertia={{ prefetch: true, cacheFor: '10s' }}>Users</a>
<a href="/users" use:inertia={{ prefetch: true, cacheFor: 5000 }}>Users</a>
```

:::

You can also start prefetching on `mousedown` by passing the `click` value to the `prefetch` prop.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/users" prefetch="click">Users</Link>
</template>
```

== React

```jsx
import { Link } from '@inertiajs/react'

export default () => (
  <Link href="/users" prefetch="click">
    Users
  </Link>
)
```

== Svelte 4|Svelte 5

```svelte
<script>
  import { inertia } from '@inertiajs/svelte'
</script>

<a href="/users" use:inertia={{ prefetch: 'click' }}>Users</a>
```

:::

If you're confident that the user will visit a page next, you can prefetch the data on mount as well.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/users" prefetch="mount">Users</Link>
</template>
```

== React

```jsx
import { Link } from '@inertiajs/react'

export default () => (
  <Link href="/users" prefetch="mount">
    Users
  </Link>
)
```

== Svelte 4|Svelte 5

```svelte
<script>
  import { inertia } from '@inertiajs/svelte'
</script>

<a href="/users" use:inertia={{ prefetch: 'mount' }}>Users</a>
```

:::

You can also combine strategies by passing an array of values to the `prefetch` prop.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/users" :prefetch="['mount', 'hover']">Users</Link>
</template>
```

== React

```jsx
import { Link } from '@inertiajs/react'

export default () => (
  <Link href="/users" prefetch={['mount', 'hover']}>
    Users
  </Link>
)
```

== Svelte 4|Svelte 5

```svelte
<script>
  import { inertia } from '@inertiajs/svelte'
</script>

<a href="/users" use:inertia={{ prefetch: ['mount', 'hover'] }}>Users</a>
```

:::

## Programmatic prefetching

You can also prefetch data programmatically using `router.prefetch`. The signature is identical to `router.visit` with the exception of a third argument that allows you to specify prefetch options.

When the `cacheFor` option is not specified, it defaults to 30 seconds.

```js
router.prefetch('/users', { method: 'get', data: { page: 2 } })

router.prefetch(
  '/users',
  { method: 'get', data: { page: 2 } },
  { cacheFor: '1m' },
)
```

To make this even easier, Inertia offers a prefetch helper. This helper provides some additional insight into the request, such as the last updated timestamp and if the request is currently prefetching.

:::tabs key:frameworks
== Vue

```js
import { usePrefetch } from '@inertiajs/vue3'

const { lastUpdatedAt, isPrefetching, isPrefetched } = usePrefetch(
  '/users',
  { method: 'get', data: { page: 2 } },
  { cacheFor: '1m' },
)
```

== React

```js
import { usePrefetch } from '@inertiajs/react'

const { lastUpdatedAt, isPrefetching, isPrefetched } = usePrefetch(
  '/users',
  { method: 'get', data: { page: 2 } },
  { cacheFor: '1m' },
)
```

== Svelte 4|Svelte 5

```js
import { usePrefetch } from '@inertiajs/svelte'

const { lastUpdatedAt, isPrefetching, isPrefetched } = usePrefetch(
  '/users',
  { method: 'get', data: { page: 2 } },
  { cacheFor: '1m' },
)
```

:::

## Flushing prefetch cache

You can flush the prefetch cache by calling `router.flushAll`. This will remove all cached data for all pages.

If you want to flush the cache for a specific page, you can pass the page URL and options to the `router.flush` method.

Furthermore, if you are using the prefetch helper, it will return a `flush` method for you to use for that specific page.

```js
// Flush all prefetch cache
router.flushAll()

// Flush cache for a specific page
router.flush('/users', { method: 'get', data: { page: 2 } })

// Flush cache for a specific page
const { flush } = usePrefetch('/users', { method: 'get', data: { page: 2 } })
flush()
```

## Stale while revalidate

By default, Inertia will fetch a fresh copy of the data when the user visits the page if the cached data is older than the cache duration. You can customize this behavior by passing a tuple to the `cacheFor` prop.

The first value in the array represents the number of seconds the cache is considered fresh, while the second value defines how long it can be served as stale data before fetching data from the server is necessary.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/users" prefetch :cacheFor="['30s', '1m']">Users</Link>
</template>
```

== React

```jsx
import { Link } from '@inertiajs/react'

export default () => (
  <Link href="/users" prefetch cacheFor={['30s', '1m']}>
    Users
  </Link>
)
```

== Svelte 4|Svelte 5

```svelte
<script>
  import { inertia } from '@inertiajs/svelte'
</script>

<a href="/users" use:inertia={{ prefetch: true, cacheFor: ['30s', '1m'] }}>
  Users
</a>
```

:::

### How it works

If a request is made within the fresh period (before the first value), the cache is returned immediately without making a request to the server.

If a request is made during the stale period (between the two values), the stale value is served to the user, and a request is made in the background to refresh the cached value. Once the value is returned, the data is merged into the page so the user has the most recent data.

If a request is made after the second value, the cache is considered expired, and the value is fetched from the sever as a regular request.
