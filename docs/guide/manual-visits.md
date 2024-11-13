# Manual visits

In addition to [creating links](/guide/links.md), it's also possible to manually make Inertia visits / requests programmatically via JavaScript. This is accomplished via the `router.visit()` method.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.visit(url, {
  method: 'get',
  data: {},
  replace: false,
  preserveState: false,
  preserveScroll: false,
  only: [],
  except: [],
  headers: {},
  errorBag: null,
  forceFormData: false,
  queryStringArrayFormat: 'brackets',
  async: false,
  showProgress: true,
  fresh: false,
  reset: [],
  preserveUrl: false,
  prefetch: false,
  onCancelToken: (cancelToken) => {},
  onCancel: () => {},
  onBefore: (visit) => {},
  onStart: (visit) => {},
  onProgress: (progress) => {},
  onSuccess: (page) => {},
  onError: (errors) => {},
  onFinish: (visit) => {},
  onPrefetching: () => {},
  onPrefetched: () => {},
})
```

== React

```js
import { router } from '@inertiajs/react'

router.visit(url, {
  method: 'get',
  data: {},
  replace: false,
  preserveState: false,
  preserveScroll: false,
  only: [],
  except: [],
  headers: {},
  errorBag: null,
  forceFormData: false,
  queryStringArrayFormat: 'brackets',
  async: false,
  showProgress: true,
  fresh: false,
  reset: [],
  preserveUrl: false,
  prefetch: false,
  onCancelToken: (cancelToken) => {},
  onCancel: () => {},
  onBefore: (visit) => {},
  onStart: (visit) => {},
  onProgress: (progress) => {},
  onSuccess: (page) => {},
  onError: (errors) => {},
  onFinish: (visit) => {},
  onPrefetching: () => {},
  onPrefetched: () => {},
})
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.visit(url, {
  method: 'get',
  data: {},
  replace: false,
  preserveState: false,
  preserveScroll: false,
  only: [],
  except: [],
  headers: {},
  errorBag: null,
  forceFormData: false,
  queryStringArrayFormat: 'brackets',
  async: false,
  showProgress: true,
  fresh: false,
  reset: [],
  preserveUrl: false,
  prefetch: false,
  onCancelToken: (cancelToken) => {},
  onCancel: () => {},
  onBefore: (visit) => {},
  onStart: (visit) => {},
  onProgress: (progress) => {},
  onSuccess: (page) => {},
  onError: (errors) => {},
  onFinish: (visit) => {},
  onPrefetching: () => {},
  onPrefetched: () => {},
})
```

:::

However, it's generally more convenient to use one of Inertia's shortcut request methods. These methods share all the same options as `router.visit()`.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.get(url, data, options)
router.post(url, data, options)
router.put(url, data, options)
router.patch(url, data, options)
router.delete(url, options)
router.reload(options) // Uses the current URL
```

== React

```js
import { router } from '@inertiajs/react'

router.get(url, data, options)
router.post(url, data, options)
router.put(url, data, options)
router.patch(url, data, options)
router.delete(url, options)
router.reload(options) // Uses the current URL
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.get(url, data, options)
router.post(url, data, options)
router.put(url, data, options)
router.patch(url, data, options)
router.delete(url, options)
router.reload(options) // Uses the current URL
```

:::

The `reload()` method is a convenient, shorthand method that automatically visits the current page with `preserveState` and `preserveScroll` both set to `true`, making it the perfect method to invoke when you just want to reload the current page's data.

## Method

When making manual visits, you may use the `method` option to set the request's HTTP method to `get`, `post`, `put`, `patch` or `delete`. The default method is `get`.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.visit(url, { method: 'post' })
```

== React

```js
import { router } from '@inertiajs/react'

router.visit(url, { method: 'post' })
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.visit(url, { method: 'post' })
```

:::

> [!WARNING]
> Uploading files via `put` or `patch` is not supported in Rails. Instead, make the request via `post`, including a `_method` attribute or a `X-HTTP-METHOD-OVERRIDE` header set to `put` or `patch`. For more info see [`Rack::MethodOverride`](https://github.com/rack/rack/blob/main/lib/rack/method_override.rb).

# Data

You may use the `data` option to add data to the request.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.visit('/users', {
  method: 'post',
  data: {
    name: 'John Doe',
    email: 'john.doe@example.com',
  },
})
```

== React

```js
import { router } from '@inertiajs/react'

router.visit('/users', {
  method: 'post',
  data: {
    name: 'John Doe',
    email: 'john.doe@example.com',
  },
})
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.visit('/users', {
  method: 'post',
  data: {
    name: 'John Doe',
    email: 'john.doe@example.com',
  },
})
```

:::

For convenience, the `get()`, `post()`, `put()`, and `patch()` methods all accept data as their second argument.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.post('/users', {
  name: 'John Doe',
  email: 'john.doe@example.com',
})
```

== React

```js
import { router } from '@inertiajs/react'

router.post('/users', {
  name: 'John Doe',
  email: 'john.doe@example.com',
})
```

== Svelte 4|Svelte 5

```js

```

import { router } from '@inertiajs/svelte'

router.post('/users', {
name: 'John Doe',
email: 'john.doe@example.com',
})
:::

## Custom headers

The `headers` option allows you to add custom headers to a request.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.post('/users', data, {
  headers: {
    'Custom-Header': 'value',
  },
})
```

== React

```js
import { router } from '@inertiajs/react'

router.post('/users', data, {
  headers: {
    'Custom-Header': 'value',
  },
})
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.post('/users', data, {
  headers: {
    'Custom-Header': 'value',
  },
})
```

:::

> [!NOTE]
> The headers Inertia uses internally to communicate its state to the server take priority and therefore cannot be overwritten.

## File uploads

When making visits / requests that include files, Inertia will automatically convert the request data into a `FormData` object. If you would like the request to always use a `FormData` object, you may use the `forceFormData` option.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.post('/companies', data, {
  forceFormData: true,
})
```

== React

```js
import { router } from '@inertiajs/react'

router.post('/companies', data, {
  forceFormData: true,
})
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.post('/companies', data, {
  forceFormData: true,
})
```

:::

For more information on uploading files, please consult the dedicated [file uploads](/guide/file-uploads.md) documentation.

## Browser history

When making visits, Inertia automatically adds a new entry into the browser history. However, it's also possible to replace the current history entry by setting the `replace` option to `true`.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.get('/users', { search: 'John' }, { replace: true })
```

== React

```js
import { router } from '@inertiajs/react'

router.get('/users', { search: 'John' }, { replace: true })
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.get('/users', { search: 'John' }, { replace: true })
```

:::

> [!NOTE]
> Visits made to the same URL automatically set `replace` to `true`.

## State preservation

By default, page visits to the same page create a fresh page component instance. This causes any local state, such as form inputs, scroll positions, and focus states to be lost.

However, in some situations, it's necessary to preserve the page component state. For example, when submitting a form, you need to preserve your form data in the event that form validation fails on the server.

For this reason, the `post`, `put`, `patch`, `delete`, and `reload` methods all set the `preserveState` option to `true` by default.

You can instruct Inertia to preserve the component's state when using the `get` method by setting the `preserveState` option to `true`.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.get('/users', { search: 'John' }, { preserveState: true })
```

== React

```js
import { router } from '@inertiajs/react'

router.get('/users', { search: 'John' }, { preserveState: true })
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.get('/users', { search: 'John' }, { preserveState: true })
```

:::

You can also lazily evaluate the `preserveState` option based on the response by providing a callback to the `preserveState` option.

If you'd like to only preserve state if the response includes validation errors, set the `preserveState` option to `"errors"`.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.get('/users', { search: 'John' }, { preserveState: 'errors' })
```

== React

```js
import { router } from '@inertiajs/react'

router.get('/users', { search: 'John' }, { preserveState: 'errors' })
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.get('/users', { search: 'John' }, { preserveState: 'errors' })
```

:::

You can also lazily evaluate the `preserveState` option based on the response by providing a callback.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.post('/users', data, {
  preserveState: (page) => page.props.someProp === 'value',
})
```

== React

```js
import { router } from '@inertiajs/react'

router.post('/users', data, {
  preserveState: (page) => page.props.someProp === 'value',
})
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.post('/users', data, {
  preserveState: (page) => page.props.someProp === 'value',
})
```

:::

## Scroll preservation

When navigating between pages, Inertia mimics default browser behavior by automatically resetting the scroll position of the document body (as well as any [scroll regions](/guide/scroll-management.md#scroll-regions) you've defined) back to the top of the page.

You can disable this behaviour by setting the `preserveScroll` option to `false`.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.visit(url, { preserveScroll: false })
```

== React

```js
import { router } from '@inertiajs/react'

router.visit(url, { preserveScroll: false })
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.visit(url, { preserveScroll: false })
```

:::

If you'd like to only preserve the scroll position if the response includes validation errors, set the `preserveScroll` option to `"errors"`.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.visit(url, { preserveScroll: 'errors' })
```

== React

```js
import { router } from '@inertiajs/react'

router.visit(url, { preserveScroll: 'errors' })
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.visit(url, { preserveScroll: 'errors' })
```

:::

You can also lazily evaluate the `preserveScroll` option based on the response by providing a callback.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.post('/users', data, {
  preserveScroll: (page) => page.props.someProp === 'value',
})
```

== React

```js
import { router } from '@inertiajs/react'

router.post('/users', data, {
  preserveScroll: (page) => page.props.someProp === 'value',
})
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.post('/users', data, {
  preserveScroll: (page) => page.props.someProp === 'value',
})
```

:::

For more information regarding this feature, please consult the [scroll management](/guide/scroll-management.md) documentation.

## Partial reloads

The `only` option allows you to request a subset of the props (data) from the server on subsequent visits to the same page, thus making your application more efficient since it does not need to retrieve data that the page is not interested in refreshing.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.visit('/users', { data: { search: 'John' }, only: ['users'] })
```

== React

```js
import { router } from '@inertiajs/react'

router.visit('/users', { data: { search: 'John' }, only: ['users'] })
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.visit('/users', { data: { search: 'John' }, only: ['users'] })
```

:::

For more information on this feature, please consult the [partial reloads](/guide/partial-reloads.md) documentation.

## Visit cancellation

You can cancel a visit using a cancel token, which Inertia automatically generates and provides via the `onCancelToken()` callback prior to making the visit.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.post('/users', data, {
  onCancelToken: (cancelToken) => (this.cancelToken = cancelToken),
})

// Cancel the visit...
this.cancelToken.cancel()
```

== React

```js
import { router } from '@inertiajs/react'

router.post('/users', data, {
  onCancelToken: (cancelToken) => (this.cancelToken = cancelToken),
})

// Cancel the visit...
this.cancelToken.cancel()
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.post('/users', data, {
  onCancelToken: (cancelToken) => (this.cancelToken = cancelToken),
})

// Cancel the visit...
this.cancelToken.cancel()
```

:::

The `onCancel()` and `onFinish()` event callbacks will be executed when a visit is cancelled.

## Event callbacks

In addition to Inertia's [global events](/guide/events.md), Inertia also provides a number of per-visit event callbacks.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.post('/users', data, {
  onBefore: (visit) => {},
  onStart: (visit) => {},
  onProgress: (progress) => {},
  onSuccess: (page) => {},
  onError: (errors) => {},
  onCancel: () => {},
  onFinish: (visit) => {},
})
```

== React

```js
import { router } from '@inertiajs/react'

router.post('/users', data, {
  onBefore: (visit) => {},
  onStart: (visit) => {},
  onProgress: (progress) => {},
  onSuccess: (page) => {},
  onError: (errors) => {},
  onCancel: () => {},
  onFinish: (visit) => {},
})
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.post('/users', data, {
  onBefore: (visit) => {},
  onStart: (visit) => {},
  onProgress: (progress) => {},
  onSuccess: (page) => {},
  onError: (errors) => {},
  onCancel: () => {},
  onFinish: (visit) => {},
})
```

:::

Returning `false` from the `onBefore()` callback will cause the visit to be cancelled.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.delete(`/users/${user.id}`, {
  onBefore: () => confirm('Are you sure you want to delete this user?'),
})
```

== React

```js
import { router } from '@inertiajs/react'

router.delete(`/users/${user.id}`, {
  onBefore: () => confirm('Are you sure you want to delete this user?'),
})
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.delete(`/users/${user.id}`, {
  onBefore: () => confirm('Are you sure you want to delete this user?'),
})
```

:::

It's also possible to return a promise from the `onSuccess()` and `onError()` callbacks. When doing so, the "finish" event will be delayed until the promise has resolved.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.post(url, {
  onSuccess: () => {
    return Promise.all([this.doThing(), this.doAnotherThing()])
  },
  onFinish: (visit) => {
    // This won't be called until doThing()
    // and doAnotherThing() have finished.
  },
})
```

== React

```js
import { router } from '@inertiajs/react'

router.post(url, {
  onSuccess: () => {
    return Promise.all([this.doThing(), this.doAnotherThing()])
  },
  onFinish: (visit) => {
    // This won't be called until doThing()
    // and doAnotherThing() have finished.
  },
})
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.post(url, {
  onSuccess: () => {
    return Promise.all([this.doThing(), this.doAnotherThing()])
  },
  onFinish: (visit) => {
    // This won't be called until doThing()
    // and doAnotherThing() have finished.
  },
})
```

:::
