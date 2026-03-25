# Optimistic Updates

Inertia allows you to update the UI immediately without waiting for the server to respond, such as incrementing a like counter, toggling a bookmark, or adding an item to a list. Optimistic updates apply changes instantly while the request is in flight, automatically rolling back if the request fails.

## Router Visits

You may chain the `optimistic()` method before any router visit. The callback receives the current page props and should return a partial update to apply immediately.

:::tabs key:frameworks

== Vue

```js
import { router } from '@inertiajs/vue3'

router
  .optimistic((props) => ({
    post: {
      ...props.post,
      likes: props.post.likes + 1,
    },
  }))
  .post(`/posts/${post.id}/like`)
```

== React

```js
import { router } from '@inertiajs/react'

router
  .optimistic((props) => ({
    post: {
      ...props.post,
      likes: props.post.likes + 1,
    },
  }))
  .post(`/posts/${post.id}/like`)
```

== Svelte

```js
import { router } from '@inertiajs/svelte'

router
  .optimistic((props) => ({
    post: {
      ...props.post,
      likes: props.post.likes + 1,
    },
  }))
  .post(`/posts/${post.id}/like`)
```

:::

The optimistic update is applied immediately to the current page's props, so your component re-renders with the new values before the request is sent. When the server responds, Inertia replaces the optimistic data with the server's response. If the request fails, the props are automatically reverted to their original values.

## Form Component

The `<Form>` component supports optimistic updates via the `optimistic` prop. Since the component manages input data internally, the form data is provided as a second callback argument.

:::tabs key:frameworks

== Vue

```vue
<template>
  <Form
    action="/todos"
    method="post"
    :optimistic="
      (props, data) => ({
        todos: [
          ...props.todos,
          { id: Date.now(), name: data.name, done: false },
        ],
      })
    "
  >
    <input type="text" name="name" />
    <button type="submit">Add Todo</button>
  </Form>
</template>
```

== React

```jsx
<Form
  action="/todos"
  method="post"
  optimistic={(props, data) => ({
    todos: [...props.todos, { id: Date.now(), name: data.name, done: false }],
  })}
>
  <input type="text" name="name" />
  <button type="submit">Add Todo</button>
</Form>
```

== Svelte

```svelte
<Form
  action="/todos"
  method="post"
  optimistic={(props, data) => ({
    todos: [...props.todos, { id: Date.now(), name: data.name, done: false }],
  })}
>
  <input type="text" name="name" />
  <button type="submit">Add Todo</button>
</Form>
```

:::

## Form Helper

The `useForm` helper also supports optimistic updates via the same `optimistic()` method.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { useForm } from '@inertiajs/vue3'

const props = defineProps({ posts: Array })

const form = useForm({
  title: '',
})

function save() {
  form
    .optimistic((props) => ({
      posts: [...props.posts, { title: form.title }],
    }))
    .post('/posts')
}
</script>

<template>
  <input v-model="form.title" />
  <button @click="save" :disabled="form.processing">Save</button>
</template>
```

== React

```jsx
import { useForm } from '@inertiajs/react'

export default function Posts({ posts }) {
  const { data, setData, optimistic, post, processing } = useForm({
    title: '',
  })

  function save(e) {
    e.preventDefault()
    optimistic((props) => ({
      posts: [...props.posts, { title: data.title }],
    }))
    post('/posts')
  }

  return (
    <form onSubmit={save}>
      <input
        value={data.title}
        onChange={(e) => setData('title', e.target.value)}
      />
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
  import { useForm } from '@inertiajs/svelte'

  let { posts } = $props()

  const form = useForm({
    title: '',
  })

  function save() {
    form
      .optimistic((props) => ({
        posts: [...props.posts, { title: form.title }],
      }))
      .post('/posts')
  }
</script>

<input bind:value={form.title} />
<button onclick={save} disabled={form.processing}>Save</button>
```

:::

## HTTP Requests

The [`useHttp`](/guide/http-requests) hook supports optimistic updates as well. Since HTTP requests don't interact with Inertia's page props, the optimistic callback receives and updates the form's own data. On failure, the form data is reverted to its pre-request state.

:::tabs key:frameworks

== Vue

```js
import { useHttp } from '@inertiajs/vue3'

const form = useHttp({
  likes: 0,
})

form
  .optimistic((data) => ({
    likes: data.likes + 1,
  }))
  .post('/api/likes')
```

== React

```js
import { useHttp } from '@inertiajs/react'

const { optimistic, post } = useHttp({
  likes: 0,
})

optimistic((data) => ({
  likes: data.likes + 1,
}))
post('/api/likes')
```

== Svelte

```js
import { useHttp } from '@inertiajs/svelte'

const form = useHttp({
  likes: 0,
})

form
  .optimistic((data) => ({
    likes: data.likes + 1,
  }))
  .post('/api/likes')
```

:::

## How It Works

When an optimistic update is applied:

1. The returned props are compared against the current page props, and only the keys that actually changed are snapshotted
2. The callback's return value is merged into the current data
3. The request is sent to the server
4. On success, the server's response replaces the optimistic data
5. On failure, only the snapshotted keys are reverted, rolling back the optimistic changes

The callback should return a **partial** object containing only the keys you wish to update. The returned values are shallow-merged with the current data.

### Automatic Rollback

Optimistic state is automatically reverted in several scenarios:

- **Validation errors (422)**: The optimistic state is reverted and the validation errors are preserved
- **Server errors**: When the request fails for any other reason, the original state is restored
- **Interrupted visits**: When a new visit interrupts an in-flight request, the previous optimistic state is restored before the new optimistic update is applied

### Concurrent Updates

Multiple optimistic requests may be in flight at the same time. Inertia tracks which props each optimistic update touched, and server responses will not overwrite a prop until the last optimistic request that modified it has resolved.

## Inline Option

You may also pass the optimistic callback directly in the visit options instead of chaining.

:::tabs key:frameworks

== Vue

```js
import { router } from '@inertiajs/vue3'

router.post(
  `/posts/${post.id}/like`,
  {},
  {
    optimistic: (props) => ({
      post: { ...props.post, likes: props.post.likes + 1 },
    }),
  },
)
```

== React

```js
import { router } from '@inertiajs/react'

router.post(
  `/posts/${post.id}/like`,
  {},
  {
    optimistic: (props) => ({
      post: { ...props.post, likes: props.post.likes + 1 },
    }),
  },
)
```

== Svelte

```js
import { router } from '@inertiajs/svelte'

router.post(
  `/posts/${post.id}/like`,
  {},
  {
    optimistic: (props) => ({
      post: { ...props.post, likes: props.post.likes + 1 },
    }),
  },
)
```

:::

The inline option works with `useHttp` submit methods as well.

```js
form.post('/api/likes', {
  optimistic: (data) => ({
    likes: data.likes + 1,
  }),
})
```
