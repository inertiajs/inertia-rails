# HTTP Requests

@available_since core=3.0.0

Not every request needs to trigger an Inertia page visit. For calls to an external API or fetching data from a non-Inertia endpoint, the `useHttp` hook provides the same developer experience as `useForm`, but for standalone HTTP requests.

## Basic Usage

The `useHttp` hook accepts initial data and returns reactive state along with methods for making HTTP requests.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { useHttp } from '@inertiajs/vue3'

const http = useHttp({
  query: '',
})

function search() {
  http.get('/api/search', {
    onSuccess: (response) => {
      console.log(response)
    },
  })
}
</script>

<template>
  <input v-model="http.query" @input="search" />
  <div v-if="http.processing">Searching...</div>
</template>
```

== React

```jsx
import { useHttp } from '@inertiajs/react'

export default function Search() {
  const { data, setData, get, processing } = useHttp({
    query: '',
  })

  function search(e) {
    setData('query', e.target.value)
    get('/api/search', {
      onSuccess: (response) => {
        console.log(response)
      },
    })
  }

  return (
    <>
      <input value={data.query} onChange={search} />
      {processing && <div>Searching...</div>}
    </>
  )
}
```

== Svelte

```svelte
<script>
  import { useHttp } from '@inertiajs/svelte'

  const http = useHttp({
    query: '',
  })

  function search() {
    http.get('/api/search', {
      onSuccess: (response) => {
        console.log(response)
      },
    })
  }
</script>

<input bind:value={http.query} oninput={search} />
{#if http.processing}
  <div>Searching...</div>
{/if}
```

:::

Unlike router visits, `useHttp` requests do not trigger page navigation or interact with Inertia's page lifecycle. They are plain HTTP requests that return JSON responses.

## Submitting Data

The hook provides `get`, `post`, `put`, `patch`, and `delete` convenience methods. A generic `submit` method is also available for dynamic HTTP methods.

:::tabs key:frameworks

== Vue

```js
http.get(url, options)
http.post(url, options)
http.put(url, options)
http.patch(url, options)
http.delete(url, options)
http.submit(method, url, options)
```

== React

```js
const {
  get,
  post,
  put,
  patch,
  delete: destroy,
  submit,
} = useHttp({
  /*...*/
})

get(url, options)
post(url, options)
put(url, options)
patch(url, options)
destroy(url, options)
submit(method, url, options)
```

== Svelte

```js
http.get(url, options)
http.post(url, options)
http.put(url, options)
http.patch(url, options)
http.delete(url, options)
http.submit(method, url, options)
```

:::

Each method returns a `Promise` that resolves with the parsed JSON response data.

:::tabs key:frameworks

== Vue

```js
const response = await http.post('/api/comments', {
  onError: (errors) => {
    console.log(errors)
  },
})
```

== React

```js
const response = await post('/api/comments', {
  onError: (errors) => {
    console.log(errors)
  },
})
```

== Svelte

```js
const response = await http.post('/api/comments', {
  onError: (errors) => {
    console.log(errors)
  },
})
```

:::

## Reactive State

The `useHttp` hook exposes the same reactive properties as `useForm`:

| Property             | Type             | Description                                       |
| -------------------- | ---------------- | ------------------------------------------------- |
| `errors`             | `object`         | Validation errors keyed by field name             |
| `hasErrors`          | `boolean`        | Whether validation errors exist                   |
| `processing`         | `boolean`        | Whether a request is in progress                  |
| `progress`           | `object \| null` | Upload progress with `percentage` and `total`     |
| `wasSuccessful`      | `boolean`        | Whether the last request was successful           |
| `recentlySuccessful` | `boolean`        | `true` for two seconds after a successful request |
| `isDirty`            | `boolean`        | Whether the data differs from its defaults        |

## Validation Errors

When a request returns a `422` status code, the hook automatically parses validation errors and makes them available through the `errors` property.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { useHttp } from '@inertiajs/vue3'

const http = useHttp({
  name: '',
  email: '',
})

function save() {
  http.post('/api/users')
}
</script>

<template>
  <input v-model="http.name" />
  <div v-if="http.errors.name">{{ http.errors.name }}</div>

  <input v-model="http.email" />
  <div v-if="http.errors.email">{{ http.errors.email }}</div>

  <button @click="save" :disabled="http.processing">Save</button>
</template>
```

== React

```jsx
import { useHttp } from '@inertiajs/react'

export default function CreateUser() {
  const { data, setData, post, errors, processing } = useHttp({
    name: '',
    email: '',
  })

  function save(e) {
    e.preventDefault()
    post('/api/users')
  }

  return (
    <form onSubmit={save}>
      <input
        value={data.name}
        onChange={(e) => setData('name', e.target.value)}
      />
      {errors.name && <div>{errors.name}</div>}

      <input
        value={data.email}
        onChange={(e) => setData('email', e.target.value)}
      />
      {errors.email && <div>{errors.email}</div>}

      <button type="submit" disabled={processing}>
        Save
      </button>
    </form>
  )
}
```

== Svelte

```svelte
<script>
  import { useHttp } from '@inertiajs/svelte'

  const http = useHttp({
    name: '',
    email: '',
  })

  function save() {
    http.post('/api/users')
  }
</script>

<input bind:value={http.name} />
{#if http.errors.name}
  <div>{http.errors.name}</div>
{/if}

<input bind:value={http.email} />
{#if http.errors.email}
  <div>{http.errors.email}</div>
{/if}

<button onclick={save} disabled={http.processing}>Save</button>
```

:::

## Displaying All Errors

By default, validation errors are simplified to the first error message for each field. You may chain `withAllErrors()` to receive all error messages as arrays, which is useful for fields with multiple validation rules.

:::tabs key:frameworks

== Vue

```js
const http = useHttp({
  name: '',
  email: '',
}).withAllErrors()

// http.errors.name === ['Name is required.', 'Name must be at least 3 characters.']
```

== React

```js
const http = useHttp({
  name: '',
  email: '',
}).withAllErrors()

// http.errors.name === ['Name is required.', 'Name must be at least 3 characters.']
```

== Svelte

```js
const http = useHttp({
  name: '',
  email: '',
}).withAllErrors()

// http.errors.name === ['Name is required.', 'Name must be at least 3 characters.']
```

:::

The same method is available on the [`useForm`](/guide/forms#options-2) helper and the [`<Form>`](/guide/forms#options) component.

## File Uploads

When the data includes files, the hook automatically sends the request as `multipart/form-data`. Upload progress is available through the `progress` property.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { useHttp } from '@inertiajs/vue3'

const http = useHttp({
  file: null,
})

function upload() {
  http.post('/api/uploads')
}
</script>

<template>
  <input type="file" @change="http.file = $event.target.files[0]" />
  <progress v-if="http.progress" :value="http.progress.percentage" max="100" />
  <button @click="upload" :disabled="http.processing">Upload</button>
</template>
```

== React

```jsx
import { useHttp } from '@inertiajs/react'

export default function Upload() {
  const { setData, post, progress, processing } = useHttp({
    file: null,
  })

  return (
    <>
      <input type="file" onChange={(e) => setData('file', e.target.files[0])} />
      {progress && <progress value={progress.percentage} max="100" />}
      <button onClick={() => post('/api/uploads')} disabled={processing}>
        Upload
      </button>
    </>
  )
}
```

== Svelte

```svelte
<script>
  import { useHttp } from '@inertiajs/svelte'

  const http = useHttp({
    file: null,
  })

  function upload() {
    http.post('/api/uploads')
  }
</script>

<input type="file" onchange={(e) => (http.file = e.target.files[0])} />
{#if http.progress}
  <progress value={http.progress.percentage} max="100" />
{/if}
<button onclick={upload} disabled={http.processing}>Upload</button>
```

:::

## Cancelling Requests

You may cancel an in-progress request using the `cancel()` method.

:::tabs key:frameworks

== Vue

```js
http.cancel()
```

== React

```js
const { cancel } = useHttp({
  /*...*/
})

cancel()
```

== Svelte

```js
http.cancel()
```

:::

## Optimistic Updates

The `useHttp` hook supports [optimistic updates](/guide/optimistic-updates) via the `optimistic()` method. The callback receives the current data and should return a partial update to apply immediately.

:::tabs key:frameworks

== Vue

```js
http
  .optimistic((data) => ({
    likes: data.likes + 1,
  }))
  .post('/api/likes')
```

== React

```js
const { optimistic, post } = useHttp({ likes: 0 })

optimistic((data) => ({
  likes: data.likes + 1,
}))
post('/api/likes')
```

== Svelte

```js
http
  .optimistic((data) => ({
    likes: data.likes + 1,
  }))
  .post('/api/likes')
```

:::

The update is applied synchronously. If the request fails, the data is rolled back to its previous state.

## Event Callbacks

Each submit method accepts an options object with lifecycle callbacks:

```js
http.post('/api/users', {
  onBefore: () => {
    /*...*/
  },
  onStart: () => {
    /*...*/
  },
  onProgress: (progress) => {
    /*...*/
  },
  onSuccess: (response) => {
    /*...*/
  },
  onError: (errors) => {
    /*...*/
  },
  onCancel: () => {
    /*...*/
  },
  onFinish: () => {
    /*...*/
  },
})
```

You may return `false` from `onBefore` to cancel the request.

## Precognition

The `useHttp` hook supports Precognition for real-time validation. Enable it by chaining `withPrecognition()` with the HTTP method and validation endpoint.

:::tabs key:frameworks

== Vue

```js
import { useHttp } from '@inertiajs/vue3'

const http = useHttp({
  name: '',
  email: '',
}).withPrecognition('post', '/api/users')
```

== React

```js
import { useHttp } from '@inertiajs/react'

const http = useHttp({
  name: '',
  email: '',
}).withPrecognition('post', '/api/users')
```

== Svelte

```js
import { useHttp } from '@inertiajs/svelte'

const http = useHttp({
  name: '',
  email: '',
}).withPrecognition('post', '/api/users')
```

:::

Once enabled, the `validate()`, `touch()`, `touched()`, `valid()`, and `invalid()` methods become available, working identically to [form precognition](/guide/forms#precognition).

## History State

You may persist data and errors in browser history state by providing a remember key as the first argument.

:::tabs key:frameworks

== Vue

```js
const http = useHttp('SearchData', {
  query: '',
})
```

== React

```js
const http = useHttp('SearchData', {
  query: '',
})
```

== Svelte

```js
const http = useHttp('SearchData', {
  query: '',
})
```

:::

You may exclude sensitive fields from being stored in history state using the `dontRemember()` method.

```js
const http = useHttp('Login', {
  email: '',
  token: '',
}).dontRemember('token')
```
