# Prefetching

Inertia supports prefetching data for pages that are likely to be visited next. This can be useful for improving the perceived performance of your app by allowing the data to be fetched in the background while the user is still interacting with the current page.

## Link prefetching

To prefetch data for a page, you can add the `prefetch` prop to the Inertia link component. By default, Inertia will prefetch the data for the page when the user hovers over the link for more than 75ms. You may customize this hover delay by setting the `prefetch.hoverDelay` option in your [application defaults](/guide/client-side-setup#configuring-defaults).

:::tabs key:frameworks
== Vue

```vue twoslash
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/users" prefetch>Users</Link>
</template>
```

== React

```jsx twoslash
import { Link } from '@inertiajs/react'

export default () => (
  <Link href="/users" prefetch>
    Users
  </Link>
)
```

== Svelte 4|Svelte 5

```svelte twoslash
<script>
  import { inertia } from '@inertiajs/svelte'
</script>

<a href="/users" use:inertia={{ prefetch: true }}>Users</a>
```

:::

By default, data is cached for 30 seconds before being evicted. You may customize this default value by setting the `prefetch.cacheFor` option in your [application defaults](/guide/client-side-setup#configuring-defaults). You may also customize the cache duration on a per-link basis by passing a `cacheFor` prop to the `Link` component.

:::tabs key:frameworks
== Vue

```vue twoslash
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

```jsx twoslash
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

```svelte twoslash
<script>
  import { inertia } from '@inertiajs/svelte'
</script>

<a href="/users" use:inertia={{ prefetch: true, cacheFor: '1m' }}>Users</a>
<a href="/users" use:inertia={{ prefetch: true, cacheFor: '10s' }}>Users</a>
<a href="/users" use:inertia={{ prefetch: true, cacheFor: 5000 }}>Users</a>
```

:::

Instead of prefetching on hover, you can also start prefetching on `mousedown` by passing the `click` value to the `prefetch` prop.

:::tabs key:frameworks
== Vue

```vue twoslash
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/users" prefetch="click">Users</Link>
</template>
```

== React

```jsx twoslash
import { Link } from '@inertiajs/react'

export default () => (
  <Link href="/users" prefetch="click">
    Users
  </Link>
)
```

== Svelte 4|Svelte 5

```svelte twoslash
<script>
  import { inertia } from '@inertiajs/svelte'
</script>

<a href="/users" use:inertia={{ prefetch: 'click' }}>Users</a>
```

:::

If you're confident that the user will visit a page next, you can prefetch the data on mount as well.

:::tabs key:frameworks
== Vue

```vue twoslash
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/users" prefetch="mount">Users</Link>
</template>
```

== React

```jsx twoslash
import { Link } from '@inertiajs/react'

export default () => (
  <Link href="/users" prefetch="mount">
    Users
  </Link>
)
```

== Svelte 4|Svelte 5

```svelte twoslash
<script>
  import { inertia } from '@inertiajs/svelte'
</script>

<a href="/users" use:inertia={{ prefetch: 'mount' }}>Users</a>
```

:::

You can also combine prefetch strategies by passing an array of values to the `prefetch` prop.

:::tabs key:frameworks
== Vue

```vue twoslash
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/users" :prefetch="['mount', 'hover']">Users</Link>
</template>
```

== React

```jsx twoslash
import { Link } from '@inertiajs/react'

export default () => (
  <Link href="/users" prefetch={['mount', 'hover']}>
    Users
  </Link>
)
```

== Svelte 4|Svelte 5

```svelte twoslash
<script>
  import { inertia } from '@inertiajs/svelte'
</script>

<a href="/users" use:inertia={{ prefetch: ['mount', 'hover'] }}>Users</a>
```

:::

## Programmatic prefetching

You can prefetch data programmatically using `router.prefetch`. This method's signature is identical to `router.visit` with the exception of a third argument that allows you to specify prefetch options.

When the `cacheFor` option is not specified, it defaults to 30 seconds.

```js twoslash
router.prefetch('/users', { method: 'get', data: { page: 2 } })

router.prefetch(
  '/users',
  { method: 'get', data: { page: 2 } },
  { cacheFor: '1m' },
)
```

Inertia also provides a `usePrefetch` hook that allows you to track the prefetch state for the current page. It returns information about whether the page is currently prefetching, has been prefetched, when it was last updated, and a `flush` method that flushes the cache for the current page only.

:::tabs key:frameworks
== Vue

```js twoslash
import { usePrefetch } from '@inertiajs/vue3'

const { lastUpdatedAt, isPrefetching, isPrefetched, flush } = usePrefetch()
```

== React

```js twoslash
import { usePrefetch } from '@inertiajs/react'

const { lastUpdatedAt, isPrefetching, isPrefetched, flush } = usePrefetch()
```

== Svelte 4|Svelte 5

```js twoslash
import { usePrefetch } from '@inertiajs/svelte'

const { lastUpdatedAt, isPrefetching, isPrefetched, flush } = usePrefetch()
```

:::

You can also pass visit options when you need to differentiate between different request configurations for the same URL.

:::tabs key:frameworks

== Vue

```js twoslash
import { usePrefetch } from '@inertiajs/vue3'

const { lastUpdatedAt, isPrefetching, isPrefetched, flush } = usePrefetch({
  headers: { 'X-Custom-Header': 'value' },
})
```

== React

```js twoslash
import { usePrefetch } from '@inertiajs/react'

const { lastUpdatedAt, isPrefetching, isPrefetched, flush } = usePrefetch({
  headers: { 'X-Custom-Header': 'value' },
})
```

== Svelte 4|Svelte 5

```js twoslash
import { usePrefetch } from '@inertiajs/svelte'

const { lastUpdatedAt, isPrefetching, isPrefetched, flush } = usePrefetch({
  headers: { 'X-Custom-Header': 'value' },
})
```

:::

## Cache tags

@available_since core=2.1.2

Cache tags allow you to group related prefetched data and invalidate all cached data with that tag when specific events occur.

To tag cached data, pass a `cacheTags` prop to your `Link` component.

:::tabs key:frameworks

== Vue

```vue twoslash
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/users" prefetch cache-tags="users">Users</Link>
  <Link href="/dashboard" prefetch :cache-tags="['dashboard', 'stats']">
    Dashboard
  </Link>
</template>
```

== React

```jsx twoslash
import { Link } from '@inertiajs/react'

<Link href="/users" prefetch cacheTags="users">Users</Link>
<Link href="/dashboard" prefetch cacheTags={['dashboard', 'stats']}>Dashboard</Link>
```

== Svelte 4|Svelte 5

```svelte twoslash
import {inertia} from '@inertiajs/svelte'

<a href="/users" use:inertia={{ prefetch: true, cacheTags: 'users' }}>Users</a>
<a
  href="/dashboard"
  use:inertia={{ prefetch: true, cacheTags: ['dashboard', 'stats'] }}
  >Dashboard</a
>
```

:::

When prefetching programmatically, pass `cacheTags` in the third argument to `router.prefetch`.

```js twoslash
router.prefetch('/users', {}, { cacheTags: 'users' })
router.prefetch('/dashboard', {}, { cacheTags: ['dashboard', 'stats'] })
```

## Cache invalidation

You can manually flush the prefetch cache by calling `router.flushAll` to remove all cached data, or `router.flush` to remove cache for a specific page.

```js twoslash
// Flush all prefetch cache
router.flushAll()

// Flush cache for a specific page
router.flush('/users', { method: 'get', data: { page: 2 } })

// Using the usePrefetch hook
const { flush } = usePrefetch()

// Flush cache for the current page
flush()
```

For more granular control, you can flush cached data by their tags using `router.flushByCacheTags`. This removes any cached response that contains _any_ of the specified tags.

```js twoslash
// Flush all responses tagged with 'users'
router.flushByCacheTags('users')

// Flush all responses tagged with 'dashboard' OR 'stats'
router.flushByCacheTags(['dashboard', 'stats'])
```

### Automatic cache flushing

By default, Inertia does not automatically flush the prefetch cache when you navigate to new pages. Cached data is only evicted when it expires based on the cache duration. If you want to flush all cached data on every navigation, you can set up an event listener.

:::tabs key:frameworks

== Vue

```js twoslash
import { router } from '@inertiajs/vue3'

router.on('navigate', () => router.flushAll())
```

== React

```js twoslash
import { router } from '@inertiajs/react'

router.on('navigate', () => router.flushAll())
```

== Svelte 4|Svelte 5

```js twoslash
import { router } from '@inertiajs/svelte'

router.on('navigate', () => router.flushAll())
```

:::

### Invalidate on requests

@available_since core=2.1.2

To automatically invalidate caches when making requests, pass an `invalidateCacheTags` prop to the Form component. The specified tags will be flushed when the form submission succeeds.

:::tabs key:frameworks

== Vue

```vue twoslash
<script setup>
import { Form } from '@inertiajs/vue3'
</script>

<template>
  <Form
    action="/users"
    method="post"
    :invalidate-cache-tags="['users', 'dashboard']"
  >
    <input type="text" name="name" />
    <input type="email" name="email" />
    <button type="submit">Create User</button>
  </Form>
</template>
```

== React

```jsx twoslash
import { Form } from '@inertiajs/react'

export default () => (
  <Form
    action="/users"
    method="post"
    invalidateCacheTags={['users', 'dashboard']}
  >
    <input type="text" name="name" />
    <input type="email" name="email" />
    <button type="submit">Create User</button>
  </Form>
)
```

== Svelte 4|Svelte 5

```svelte twoslash
<script>
  import { Form } from '@inertiajs/svelte'
</script>

<Form
  action="/users"
  method="post"
  invalidateCacheTags={['users', 'dashboard']}
>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Create User</button>
</Form>
```

:::

When using the `useForm` helper, you can include `invalidateCacheTags` in the visit options.

:::tabs key:frameworks

== Vue

```vue twoslash
import { useForm } from '@inertiajs/vue3' const form = useForm({ name: '',
email: '', }) const submit = () => { form.post('/users', { invalidateCacheTags:
['users', 'dashboard'] }) }
```

== React

```jsx twoslash
import { useForm } from '@inertiajs/react'

const { data, setData, post } = useForm({
  name: '',
  email: '',
})

function submit(e) {
  e.preventDefault()
  post('/users', {
    invalidateCacheTags: ['users', 'dashboard'],
  })
}
```

== Svelte 4|Svelte 5

```svelte twoslash
import { useForm } from '@inertiajs/svelte'

const form = useForm({
 name: '',
 email: '',
})

function submit() {
 $form.post('/users', {
   invalidateCacheTags: ['users', 'dashboard']
 })
}
```

:::

You can also invalidate cache tags with programmatic visits by including `invalidateCacheTags` in the options.

```js twoslash
router.delete(
  `/users/${userId}`,
  {},
  {
    invalidateCacheTags: ['users', 'dashboard'],
  },
)

router.post('/posts', postData, {
  invalidateCacheTags: ['posts', 'recent-posts'],
})
```

## Stale while revalidate

By default, Inertia will fetch a fresh copy of the data when the user visits the page if the cached data is older than the cache duration. You can customize this behavior by passing a tuple to the `cacheFor` prop.

The first value in the array represents the number of seconds the cache is considered fresh, while the second value defines how long it can be served as stale data before fetching data from the server is necessary.

:::tabs key:frameworks
== Vue

```vue twoslash
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/users" prefetch :cacheFor="['30s', '1m']">Users</Link>
</template>
```

== React

```jsx twoslash
import { Link } from '@inertiajs/react'

export default () => (
  <Link href="/users" prefetch cacheFor={['30s', '1m']}>
    Users
  </Link>
)
```

== Svelte 4|Svelte 5

```svelte twoslash
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

If a request is made during the stale period (between the two values), the stale value is served to the user, and a request is made in the background to refresh the cached data. Once the fresh data is returned, it is merged into the page so the user has the most recent data.

If a request is made after the second value, the cache is considered expired, and the page and data is fetched from the sever as a regular request.
