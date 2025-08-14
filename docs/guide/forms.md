# Forms

## Submitting forms

While it's possible to make classic HTML form submissions with Inertia, it's not recommended since they cause full-page reloads. Instead, it's better to intercept form submissions and then make the [request using Inertia](/guide/manual-visits.md).

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { reactive } from 'vue'
import { router } from '@inertiajs/vue3'

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

    <label for="last_name">Last name:</label>
    <input id="last_name" v-model="form.last_name" />

    <label for="email">Email:</label>
    <input id="email" v-model="form.email" />

    <button type="submit">Submit</button>
  </form>
</template>
```

== React

```jsx
import { useState } from 'react'
import { router } from '@inertiajs/react'

export default function Edit() {
  const [values, setValues] = useState({
    first_name: '',
    last_name: '',
    email: '',
  })

  function handleChange(e) {
    const key = e.target.id
    const value = e.target.value
    setValues((values) => ({
      ...values,
      [key]: value,
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

      <label htmlFor="last_name">Last name:</label>
      <input id="last_name" value={values.last_name} onChange={handleChange} />

      <label htmlFor="email">Email:</label>
      <input id="email" value={values.email} onChange={handleChange} />

      <button type="submit">Submit</button>
    </form>
  )
}
```

== Svelte 4

```svelte
<script>
  import { router } from '@inertiajs/svelte'

  let values = {
    first_name: null,
    last_name: null,
    email: null,
  }

  function submit() {
    router.post('/users', values)
  }
</script>

<form on:submit|preventDefault={submit}>
  <label for="first_name">First name:</label>
  <input id="first_name" bind:value={values.first_name} />

  <label for="last_name">Last name:</label>
  <input id="last_name" bind:value={values.last_name} />

  <label for="email">Email:</label>
  <input id="email" bind:value={values.email} />

  <button type="submit">Submit</button>
</form>
```

== Svelte 5

```svelte
<script>
  import { router } from '@inertiajs/svelte'

  let values = {
    first_name: null,
    last_name: null,
    email: null,
  }

  function submit(e) {
    e.preventDefault()
    router.post('/users', values)
  }
</script>

<form onsubmit={submit}>
  <label for="first_name">First name:</label>
  <input id="first_name" bind:value={values.first_name} />

  <label for="last_name">Last name:</label>
  <input id="last_name" bind:value={values.last_name} />

  <label for="email">Email:</label>
  <input id="email" bind:value={values.email} />

  <button type="submit">Submit</button>
</form>
```

:::

As you may have noticed in the example above, when using Inertia, you don't typically need to inspect form responses client-side like you would when making XHR / fetch requests manually.

Instead, your server-side route / controller typically issues a [redirect](/guide/redirects.md) response. And, Of course, there is nothing stopping you from redirecting the user right back to the page they were previously on. Using this approach, handling Inertia form submissions feels very similar to handling classic HTML form submissions.

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

## Server-side validation

Handling server-side validation errors in Inertia works a little different than handling errors from manual XHR / fetch requests. When making XHR / fetch requests, you typically inspect the response for a `422` status code and manually update the form's error state.

However, when using Inertia, a `422` response is never returned by your server. Instead, as we saw in the example above, your routes / controllers will typically return a redirect response - much like a classic, full-page form submission.

For a full discussion on handling and displaying [validation](/guide/validation.md) errors with Inertia, please consult the validation documentation.

## Form helper

Since working with forms is so common, Inertia includes a form helper designed to help reduce the amount of boilerplate code needed for handling typical form submissions. The `useForm` method provides a convenient way to manage form state, validation, and submission.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { useForm } from '@inertiajs/vue3'

const form = useForm({
  email: null,
  password: null,
  remember: false,
})
</script>

<template>
  <form @submit.prevent="form.post('/login')">
    <!-- email -->
    <input type="text" v-model="form.email" />
    <div v-if="form.errors.email">{{ form.errors.email }}</div>
    <!-- password -->
    <input type="password" v-model="form.password" />
    <div v-if="form.errors.password">{{ form.errors.password }}</div>
    <!-- remember me -->
    <input type="checkbox" v-model="form.remember" /> Remember Me
    <!-- submit -->
    <button type="submit" :disabled="form.processing">Login</button>
  </form>
</template>
```

== React

```jsx
import { useForm } from '@inertiajs/react'

const { data, setData, post, processing, errors } = useForm({
  email: '',
  password: '',
  remember: false,
})

function submit(e) {
  e.preventDefault()
  post('/login')
}

return (
  <form onSubmit={submit}>
    <input
      type="text"
      value={data.email}
      onChange={(e) => setData('email', e.target.value)}
    />
    {errors.email && <div>{errors.email}</div>}
    <input
      type="password"
      value={data.password}
      onChange={(e) => setData('password', e.target.value)}
    />
    {errors.password && <div>{errors.password}</div>}
    <input
      type="checkbox"
      checked={data.remember}
      onChange={(e) => setData('remember', e.target.checked)}
    />{' '}
    Remember Me
    <button type="submit" disabled={processing}>
      Login
    </button>
  </form>
)
```

== Svelte 4

```svelte
<script>
  import { useForm } from '@inertiajs/svelte'

  const form = useForm({
    email: null,
    password: null,
    remember: false,
  })

  function submit() {
    $form.post('/login')
  }
</script>

<form on:submit|preventDefault={submit}>
  <input type="text" bind:value={$form.email} />
  {#if $form.errors.email}
    <div class="form-error">{$form.errors.email}</div>
  {/if}
  <input type="password" bind:value={$form.password} />
  {#if $form.errors.password}
    <div class="form-error">{$form.errors.password}</div>
  {/if}
  <input type="checkbox" bind:checked={$form.remember} /> Remember Me
  <button type="submit" disabled={$form.processing}>Submit</button>
</form>
```

== Svelte 5

```svelte
<script>
  import { useForm } from '@inertiajs/svelte'

  const form = useForm({
    email: null,
    password: null,
    remember: false,
  })

  function submit(e) {
    e.preventDefault()
    $form.post('/login')
  }
</script>

<form onsubmit={submit}>
  <input type="text" bind:value={$form.email} />
  {#if $form.errors.email}
    <div class="form-error">{$form.errors.email}</div>
  {/if}
  <input type="password" bind:value={$form.password} />
  {#if $form.errors.password}
    <div class="form-error">{$form.errors.password}</div>
  {/if}
  <input type="checkbox" bind:checked={$form.remember} /> Remember Me
  <button type="submit" disabled={$form.processing}>Submit</button>
</form>
```

:::

To submit the form, you may use the `get`, `post`, `put`, `patch` and `delete` methods.

:::tabs key:frameworks
== Vue

```js
form.submit(method, url, options)
form.get(url, options)
form.post(url, options)
form.put(url, options)
form.patch(url, options)
form.delete(url, options)
```

== React

```jsx
const { submit, get, post, put, patch, delete: destroy } = useForm({ ... })

submit(method, url, options)
get(url, options)
post(url, options)
put(url, options)
patch(url, options)
destroy(url, options)
```

== Svelte 4|Svelte 5

```js
$form.submit(method, url, options)
$form.get(url, options)
$form.post(url, options)
$form.put(url, options)
$form.patch(url, options)
$form.delete(url, options)
```

:::

The submit methods support all of the typical [visit options](/guide/manual-visits.md), such as `preserveState`, `preserveScroll`, and event callbacks, which can be helpful for performing tasks on successful form submissions. For example, you might use the `onSuccess` callback to reset inputs to their original state.

:::tabs key:frameworks
== Vue

```js
form.post('/profile', {
  preserveScroll: true,
  onSuccess: () => form.reset('password'),
})
```

== React

```jsx
const { post, reset } = useForm({ ... })

post('/profile', {
preserveScroll: true,
onSuccess: () => reset('password'),
})
```

== Svelte 4|Svelte 5

```js
$form.post('/profile', {
  preserveScroll: true,
  onSuccess: () => $form.reset('password'),
})
```

:::

If you need to modify the form data before it's sent to the server, you can do so via the `transform()` method.

:::tabs key:frameworks
== Vue

```js
form
  .transform((data) => ({
    ...data,
    remember: data.remember ? 'on' : '',
  }))
  .post('/login')
```

== React

```jsx
const { transform } = useForm({ ... })

transform((data) => ({
  ...data,
  remember: data.remember ? 'on' : '',
}))
```

== Svelte 4|Svelte 5

```js
$form
  .transform((data) => ({
    ...data,
    remember: data.remember ? 'on' : '',
  }))
  .post('/login')
```

:::

You can use the `processing` property to track if a form is currently being submitted. This can be helpful for preventing double form submissions by disabling the submit button.

:::tabs key:frameworks
== Vue

```vue
<button type="submit" :disabled="form.processing">Submit</button>
```

== React

```jsx
const { processing } = useForm({ ... })

<button type="submit" disabled={processing}>Submit</button>
```

== Svelte 4|Svelte 5

```svelte
<button type="submit" disabled={$form.processing}>Submit</button>
```

:::

If your form is uploading files, the current progress event is available via the `progress` property, allowing you to easily display the upload progress.

:::tabs key:frameworks
== Vue

```vue
<progress v-if="form.progress" :value="form.progress.percentage" max="100">
  {{ form.progress.percentage }}%
</progress>
```

== React

```jsx
const { progress } = useForm({ ... })

{progress && (
  <progress value={progress.percentage} max="100">
    {progress.percentage}%
  </progress>
)}
```

== Svelte 4|Svelte 5

```svelte
{#if $form.progress}
  <progress value={$form.progress.percentage} max="100">
    {$form.progress.percentage}%
  </progress>
{/if}
```

:::

If there are form validation errors, they are available via the `errors` property. When building Rails powered Inertia applications, form errors will automatically be populated when your application throws instances of `ActiveRecord::RecordInvalid`, such as when using `#save!`.

:::tabs key:frameworks
== Vue

```vue
<div v-if="form.errors.email">{{ form.errors.email }}</div>
```

== React

```jsx
const { errors } = useForm({ ... })

{errors.email && <div>{errors.email}</div>}
```

== Svelte 4|Svelte 5

```svelte
{#if $form.errors.email}
  <div>{$form.errors.email}</div>
{/if}
```

:::

> [!NOTE]
> For a more thorough discussion of form validation and errors, please consult the [validation documentation](/guide/validation.md).

To determine if a form has any errors, you may use the `hasErrors` property. To clear form errors, use the `clearErrors()` method.

:::tabs key:frameworks
== Vue

```js
// Clear all errors...
form.clearErrors()

// Clear errors for specific fields...
form.clearErrors('field', 'anotherfield')
```

== React

```jsx
const { clearErrors } = useForm({ ... })

// Clear all errors...
clearErrors()

// Clear errors for specific fields...
clearErrors('field', 'anotherfield')
```

== Svelte 4|Svelte 5

```js
// Clear all errors...
$form.clearErrors()

// Clear errors for specific fields...
$form.clearErrors('field', 'anotherfield')
```

:::

If you're using a client-side input validation libraries or do client-side validation manually, you can set your own errors on the form using the `setError()` method.

:::tabs key:frameworks
== Vue

```js
// Set a single error...
form.setError('field', 'Your error message.')

// Set multiple errors at once...
form.setError({
  foo: 'Your error message for the foo field.',
  bar: 'Some other error for the bar field.',
})
```

== React

```jsx
const { setError } = useForm({ ... })

// Set a single error...
setError('field', 'Your error message.');

// Set multiple errors at once...
setError({
  foo: 'Your error message for the foo field.',
  bar: 'Some other error for the bar field.'
});
```

== Svelte 4|Svelte 5

```js
// Set a single error
$form.setError('field', 'Your error message.')

// Set multiple errors at once
$form.setError({
  foo: 'Your error message for the foo field.',
  bar: 'Some other error for the bar field.',
})
```

:::

> [!NOTE]
> Unlike an actual form submission, the page's props remain unchanged when manually setting errors on a form instance.

When a form has been successfully submitted, the `wasSuccessful` property will be `true`. In addition to this, forms have a `recentlySuccessful` property, which will be set to `true` for two seconds after a successful form submission. This property can be utilized to show temporary success messages.

To reset the form's values back to their default values, you can use the `reset()` method.

:::tabs key:frameworks
== Vue

```js
// Reset the form...
form.reset()

// Reset specific fields...
form.reset('field', 'anotherfield')
```

== React

```jsx
const { reset } = useForm({ ... })

// Reset the form...
reset()

// Reset specific fields...
reset('field', 'anotherfield')
```

== Svelte 4|Svelte 5

```js
// Reset the form...
$form.reset()

// Reset specific fields...
$form.reset('field', 'anotherfield')
```

:::

@available_since core=2.0.15

Sometimes, you may want to restore your form fields to their default values and clear any validation errors at the same time. Instead of calling `reset()` and `clearErrors()` separately, you can use the `resetAndClearErrors()` method, which combines both actions into a single call.

:::tabs key:frameworks

== Vue
```js
// Reset the form and clear all errors...
form.resetAndClearErrors()

// Reset specific fields and clear their errors...
form.resetAndClearErrors('field', 'anotherfield')
```

== React

```jsx
const { resetAndClearErrors } = useForm({ ... })

// Reset the form and clear all errors...
resetAndClearErrors()

// Reset specific fields and clear their errors...
resetAndClearErrors('field', 'anotherfield')
```

== Svelte 4|Svelte 5

```js
// Reset the form and clear all errors...
$form.resetAndClearErrors()

// Reset specific fields and clear their errors...
$form.resetAndClearErrors('field', 'anotherfield')
```

:::

If your form's default values become outdated, you can use the `defaults()` method to update them. Then, the form will be reset to the correct values the next time the `reset()` method is invoked.

:::tabs key:frameworks
== Vue

```js
// Set the form's current values as the new defaults...
form.defaults()

// Update the default value of a single field...
form.defaults('email', 'updated-default@example.com')

// Update the default value of multiple fields...
form.defaults({
  name: 'Updated Example',
  email: 'updated-default@example.com',
})
```

== React

```jsx
const { setDefaults } = useForm({ ... })

// Set the form's current values as the new defaults...
setDefaults()

// Update the default value of a single field...
setDefaults('email', 'updated-default@example.com')

// Update the default value of multiple fields...
setDefaults({
  name: 'Updated Example',
  email: 'updated-default@example.com',
})
```

== Svelte 4|Svelte 5

```js
// Set the form's current values as the new defaults...
$form.defaults()

// Update the default value of a single field...
$form.defaults('email', 'updated-default@example.com')

// Change the default value of multiple fields...
$form.defaults({
  name: 'Updated Example',
  email: 'updated-default@example.com',
})
```

:::

To determine if a form has any changes, you may use the `isDirty` property.

:::tabs key:frameworks
== Vue

```vue
<div v-if="form.isDirty">There are unsaved form changes.</div>
```

== React

```jsx
const { isDirty } = useForm({ ... })

{isDirty && <div>There are unsaved form changes.</div>}
```

== Svelte 4|Svelte 5

```svelte
{#if $form.isDirty}
  <div>There are unsaved form changes.</div>
{/if}
```

:::

To cancel a form submission, use the `cancel()` method.

:::tabs key:frameworks
== Vue

```vue
form.cancel()
```

== React

```jsx
const { cancel } = useForm({ ... })

cancel()
```

== Svelte 4|Svelte 5

```svelte
$form.cancel()
```

:::

To instruct Inertia to store a form's data and errors in [history state](/guide/remembering-state.md), you can provide a unique form key as the first argument when instantiating your form.

:::tabs key:frameworks
== Vue

```js
import { useForm } from '@inertiajs/vue3'

const form = useForm('CreateUser', data)
const form = useForm(`EditUser:${user.id}`, data)
```

== React

```js
import { useForm } from '@inertiajs/react'

const form = useForm('CreateUser', data)
const form = useForm(`EditUser:${user.id}`, data)
```

== Svelte 4|Svelte 5

```js
import { useForm } from '@inertiajs/svelte'

const form = useForm('CreateUser', data)
const form = useForm(`EditUser:${user.id}`, data)
```

:::

## File uploads

When making requests or form submissions that include files, Inertia will automatically convert the request data into a `FormData` object.

For a more thorough discussion of file uploads, please consult the [file uploads documentation](/guide/file-uploads.md).

## XHR / fetch submissions

Using Inertia to submit forms works great for the vast majority of situations; however, in the event that you need more control over the form submission, you're free to make plain XHR or `fetch` requests instead using the library of your choice.
