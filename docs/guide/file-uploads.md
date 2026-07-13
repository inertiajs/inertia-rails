# File Uploads

## `FormData` Conversion

When making Inertia requests that include files (even nested files), Inertia will automatically convert the request data into a `FormData` object. This conversion is necessary in order to submit a `multipart/form-data` request via XHR.

If you would like the request to always use a `FormData` object regardless of whether a file is present in the data, you may provide the `forceFormData` option when making the request.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.post('/users', data, {
  forceFormData: true,
})
```

== React

```js
import { router } from '@inertiajs/react'

router.post('/users', data, {
  forceFormData: true,
})
```

== Svelte

```js
import { router } from '@inertiajs/svelte'

router.post('/users', data, {
  forceFormData: true,
})
```

:::

You can learn more about the `FormData` interface via its [MDN documentation](https://developer.mozilla.org/en-US/docs/Web/API/FormData).

## File Upload Example

Let's examine a complete file upload example using Inertia. This example includes both a `name` text input and an `avatar` file input.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { useForm } from '@inertiajs/vue3'

const form = useForm({
  name: null,
  avatar: null,
})

function submit() {
  form.post('/users')
}
</script>

<template>
  <form @submit.prevent="submit">
    <input type="text" v-model="form.name" />
    <input type="file" @input="form.avatar = $event.target.files[0]" />
    <progress v-if="form.progress" :value="form.progress.percentage" max="100">
      {{ form.progress.percentage }}%
    </progress>
    <button type="submit">Submit</button>
  </form>
</template>
```

== React

```jsx
import { useForm } from '@inertiajs/react'

const { data, setData, post, progress } = useForm({
  name: null,
  avatar: null,
})

function submit(e) {
  e.preventDefault()
  post('/users')
}

return (
  <form onSubmit={submit}>
    <input
      type="text"
      value={data.name}
      onChange={(e) => setData('name', e.target.value)}
    />
    <input type="file" onChange={(e) => setData('avatar', e.target.files[0])} />
    {progress && (
      <progress value={progress.percentage} max="100">
        {progress.percentage}%
      </progress>
    )}
    <button type="submit">Submit</button>
  </form>
)
```

== Svelte

```svelte
<script>
  import { useForm } from '@inertiajs/svelte'

  const form = useForm({
    name: null,
    avatar: null,
  })

  function submit(e) {
    e.preventDefault()
    form.post('/users')
  }
</script>

<form onsubmit={submit}>
  <input type="text" bind:value={form.name} />
  <input type="file" oninput={(e) => (form.avatar = e.target.files[0])} />
  {#if form.progress}
    <progress value={form.progress.percentage} max="100">
      {form.progress.percentage}%
    </progress>
  {/if}
  <button type="submit">Submit</button>
</form>
```

:::

This example uses the [Inertia form helper](/guide/forms#form-helper) for convenience, since the form helper provides easy access to the current upload progress. However, you are free to submit your forms using [manual Inertia visits](/guide/manual-visits) as well.

## Multipart Limitations

Uploading files using a `multipart/form-data` request is not natively supported in some server-side frameworks when using the `PUT`, `PATCH`, or `DELETE` HTTP methods. The simplest workaround for this limitation is to simply upload files using a `POST` request instead.

However, some frameworks, such as [Laravel](https://laravel.com/docs/routing#form-method-spoofing) and [Rails](https://guides.rubyonrails.org/form_helpers.html#forms-with-patch-put-or-delete-methods), support form method spoofing, which allows you to upload the files using `POST`, but have the framework handle the request as a `PUT` or `PATCH` request. This is done by including a `_method` attribute in the data of your request.

> [!NOTE]
> For more info see [`Rack::MethodOverride`](https://github.com/rack/rack/blob/main/lib/rack/method_override.rb).

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.post(`/users/${user.id}`, {
  _method: 'put',
  avatar: form.avatar,
})
```

== React

```js
import { router } from '@inertiajs/react'

router.post(`/users/${user.id}`, {
  _method: 'put',
  avatar: form.avatar,
})
```

== Svelte

```js
import { router } from '@inertiajs/svelte'

router.post(`/users/${user.id}`, {
  _method: 'put',
  avatar: form.avatar,
})
```

:::
