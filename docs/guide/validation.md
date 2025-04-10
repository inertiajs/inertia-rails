# Validation

## How it works

Handling server-side validation errors in Inertia works differently than a classic XHR-driven form that requires you to catch the validation errors from `422` responses and manually update the form's error state - because Inertia never receives `422` responses. Instead, Inertia operates much more like a standard full page form submission. Here's how:

First, you [submit your form using Inertia](/guide/forms.md). If there are server-side validation errors, you don't return those errors as a `422` JSON response. Instead, you redirect (server-side) the user back to the form page they were previously on, flashing the validation errors in the session.

```ruby
class UsersController < ApplicationController
  def create
    user = User.new(user_params)

    if user.save
      redirect_to users_url
    else
      redirect_to new_user_url, inertia: { errors: user.errors }
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
```

Next, any time these validation errors are present in the session, they automatically get shared with Inertia, making them available client-side as page props which you can display in your form. Since props are reactive, they are automatically shown when the form submission completes.

Finally, since Inertia apps never generate `422` responses, Inertia needs another way to determine if a response includes validation errors. To do this, Inertia checks the `page.props.errors` object for the existence of any errors. In the event that errors are present, the request's `onError()` callback will be called instead of the `onSuccess()` callback.

## Sharing errors

In order for your server-side validation errors to be available client-side, your server-side framework must share them via the `errors` prop. Inertia's Rails adapter do this automatically.

## Displaying errors

Since validation errors are made available client-side as page component props, you can conditionally display them based on their existence. Remember, when using Rails server adapter, the `errors` prop will automatically be available to your page.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { reactive } from 'vue'
import { router } from '@inertiajs/vue3'

defineProps({ errors: Object })

const form = reactive({
  first_name: null,
  last_name: null,
  email: null,
})

function submit() {
  router.post('/users', form)
}
</script>

<template>
  <form @submit.prevent="submit">
    <label for="first_name">First name:</label>
    <input id="first_name" v-model="form.first_name" />
    <div v-if="errors.first_name">{{ errors.first_name }}</div>
    <label for="last_name">Last name:</label>
    <input id="last_name" v-model="form.last_name" />
    <div v-if="errors.last_name">{{ errors.last_name }}</div>
    <label for="email">Email:</label>
    <input id="email" v-model="form.email" />
    <div v-if="errors.email">{{ errors.email }}</div>
    <button type="submit">Submit</button>
  </form>
</template>
```

> [!NOTE]
> When using the Vue adapters, you may also access the errors via the `$page.props.errors` object.

== React

```jsx
import { useState } from 'react'
import { router, usePage } from '@inertiajs/react'

export default function Edit() {
  const { errors } = usePage().props

  const [values, setValues] = useState({
    first_name: null,
    last_name: null,
    email: null,
  })

  function handleChange(e) {
    setValues((values) => ({
      ...values,
      [e.target.id]: e.target.value,
    }))
  }

  function handleSubmit(e) {
    e.preventDefault()
    router.post('/users', values)
  }

  return (
    <form onSubmit={handleSubmit}>
      <label htmlFor="first_name">First name:</label>
      <input
        id="first_name"
        value={values.first_name}
        onChange={handleChange}
      />
      {errors.first_name && <div>{errors.first_name}</div>}
      <label htmlFor="last_name">Last name:</label>
      <input id="last_name" value={values.last_name} onChange={handleChange} />
      {errors.last_name && <div>{errors.last_name}</div>}
      <label htmlFor="email">Email:</label>
      <input id="email" value={values.email} onChange={handleChange} />
      {errors.email && <div>{errors.email}</div>}
      <button type="submit">Submit</button>
    </form>
  )
}
```

== Svelte 4|Svelte 5

```svelte
<script>
  import { router } from '@inertiajs/svelte'

  export let errors = {}

  let values = {
    first_name: null,
    last_name: null,
    email: null,
  }

  function handleSubmit() {
    router.post('/users', values)
  }
</script>

<form on:submit|preventDefault={handleSubmit}>
  <label for="first_name">First name:</label>
  <input id="first_name" bind:value={values.first_name} />
  {#if errors.first_name}<div>{errors.first_name}</div>{/if}

  <label for="last_name">Last name:</label>
  <input id="last_name" bind:value={values.last_name} />
  {#if errors.last_name}<div>{errors.last_name}</div>{/if}

  <label for="email">Email:</label>
  <input id="email" bind:value={values.email} />
  {#if errors.email}<div>{errors.email}</div>{/if}

  <button type="submit">Submit</button>
</form>
```

:::

## Repopulating input

While handling errors in Inertia is similar to full page form submissions, Inertia offers even more benefits. In fact, you don't even need to manually repopulate old form input data.

When validation errors occur, the user is typically redirected back to the form page they were previously on. And, by default, Inertia automatically preserves the [component state](/guide/manual-visits.md#state-preservation) for `post`, `put`, `patch`, and `delete` requests. Therefore, all the old form input data remains exactly as it was when the user submitted the form.

So, the only work remaining is to display any validation errors using the `errors` prop.

## Error bags

> [!NOTE]
> If you're using the [form helper](/guide/forms.md), it's not necessary to use error bags since validation errors are automatically scoped to the form object making the request.

For pages that have more than one form, it's possible to encounter conflicts when displaying validation errors if two forms share the same field names. For example, imagine a "create company" form and a "create user" form that both have a `name` field. Since both forms will be displaying the `page.props.errors.name` validation error, generating a validation error for the `name` field in either form will cause the error to appear in both forms.

To solve this issue, you can use "error bags". Error bags scope the validation errors returned from the server within a unique key specific to that form. Continuing with our example above, you might have a `createCompany` error bag for the first form and a `createUser` error bag for the second form.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.post('/companies', data, {
  errorBag: 'createCompany',
})

router.post('/users', data, {
  errorBag: 'createUser',
})
```

== React

```jsx
import { router } from '@inertiajs/react'

router.post('/companies', data, {
  errorBag: 'createCompany',
})

router.post('/users', data, {
  errorBag: 'createUser',
})
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.post('/companies', data, {
  errorBag: 'createCompany',
})

router.post('/users', data, {
  errorBag: 'createUser',
})
```

:::

Specifying an error bag will cause the validation errors to come back from the server within `page.props.errors.createCompany` and `page.props.errors.createUser`.
