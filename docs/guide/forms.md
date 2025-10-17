# Forms

Inertia provides two primary ways to build forms: the `<Form>` component and the `useForm` helper. Both integrate with your server-side framework's validation and handle form submissions without full page reloads.

## Form component

@available_since core=2.1.0

Inertia provides a `<Form>` component that behaves much like a classic HTML form, but uses Inertia under the hood to avoid full page reloads. This is the simplest way to get started with forms in Inertia:

### Submitting forms

While it's possible to make classic HTML form submissions with Inertia, it's not recommended since they cause full-page reloads. Instead, it's better to intercept form submissions and then make the [request using Inertia](/guide/manual-visits.md).

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { Form } from '@inertiajs/vue3'
</script>

<template>
  <Form action="/users" method="post">
    <input type="text" name="name" />
    <input type="email" name="email" />
    <button type="submit">Create User</button>
  </Form>
</template>
```

== React

```jsx
import { Form } from '@inertiajs/react'

export default () => (
  <Form action="/users" method="post">
    <input type="text" name="name" />
    <input type="email" name="email" />
    <button type="submit">Create User</button>
  </Form>
)
```

== Svelte 4|Svelte 5

```svelte
<script>
  import { Form } from '@inertiajs/svelte'
</script>

<Form action="/users" method="post">
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Create User</button>
</Form>
```

:::

Just like a traditional HTML form, there is no need to attach <Vue>`v-model`</Vue><React>an `onChange` handler</React><Svelte>`bind:`</Svelte> to your input fields, just give each input a `name` attribute <Opt v="React|Svelte 5">and a `defaultValue` (if applicable)</Opt> and the `Form` component will handle the data submission for you.

The component also supports nested data structures, file uploads, and dotted key notation.

:::tabs key:frameworks

== Vue

```vue
<Form action="/reports" method="post">
  <input type="text" name="name" />
  <textarea name="report[description]"></textarea>
  <input type="text" name="report[tags][]" />
  <input type="file" name="documents" multiple />
  <button type="submit">Create Report</button>
</Form>
```

== React

```jsx
<Form action="/reports" method="post">
  <input type="text" name="name" />
  <textarea name="report[description]"></textarea>
  <input type="text" name="report[tags][]" />
  <input type="file" name="documents" multiple />
  <button type="submit">Create Report</button>
</Form>
```

== Svelte 4|Svelte 5

```svelte
<Form action="/reports" method="post">
  <input type="text" name="name" />
  <textarea name="report[description]"></textarea>
  <input type="text" name="report[tags][]" />
  <input type="file" name="documents" multiple />
  <button type="submit">Create Report</button>
</Form>
```

:::

You can pass a `transform` prop to modify the form data before submission. This is useful for injecting additional fields or transforming existing data, although hidden inputs work too.

:::tabs key:frameworks

== Vue

```vue
<Form
  action="/posts"
  method="post"
  :transform="(data) => ({ ...data, user_id: 123 })"
>
  <input type="text" name="title" />
  <button type="submit">Create Post</button>
</Form>
```

== React

```jsx
<Form
  action="/posts"
  method="post"
  transform={(data) => ({ ...data, user_id: 123 })}
>
  <input type="text" name="title" />
  <button type="submit">Create Post</button>
</Form>
```

== Svelte 4|Svelte 5

```svelte
<Form
  action="/posts"
  method="post"
  transform={(data) => ({ ...data, user_id: 123 })}
>
  <input type="text" name="title" />
  <button type="submit">Create Post</button>
</Form>
```

:::

### Default values

You can set default values for form inputs using standard HTML attributes. Use <React>`defaultValue`</React><Vue>`value`</Vue><Svelte4>`value`</Svelte4><Svelte5>`defaultValue` (`value` for Svelte < `5.6.0`)</Svelte5> for text inputs and textareas, and <React>`defaultChecked`</React><Vue>`checked`</Vue><Svelte4>`checked`</Svelte4><Svelte5>`defaultChecked` (`checked` for Svelte < `5.6.0`)</Svelte5> for checkboxes and radios.

:::tabs key:frameworks

== Vue

```vue
<template>
  <Form action="/users" method="post">
    <input type="text" name="name" value="John Doe" />

    <select name="country">
      <option value="us">United States</option>
      <option value="ca">Canada</option>
      <option value="uk" selected>United Kingdom</option>
    </select>

    <input type="checkbox" name="subscribe" value="yes" checked />

    <button type="submit">Submit</button>
  </Form>
</template>
```

== React

```jsx
<Form action="/users" method="post">
  <input type="text" name="name" defaultValue="John Doe" />

  <select name="country" defaultValue="uk">
    <option value="us">United States</option>
    <option value="ca">Canada</option>
    <option value="uk">United Kingdom</option>
  </select>

  <input type="checkbox" name="subscribe" value="yes" defaultChecked />

  <button type="submit">Submit</button>
</Form>
```

== Svelte 4

```svelte
<Form action="/users" method="post">
  <input type="text" name="name" value="John Doe" />

  <select name="country" value="uk">
    <option value="us">United States</option>
    <option value="ca">Canada</option>
    <option value="uk">United Kingdom</option>
  </select>

  <input type="checkbox" name="subscribe" value="yes" checked />

  <button type="submit">Submit</button>
</Form>
```

== Svelte 5

```svelte
<Form action="/users" method="post">
  <input type="text" name="name" defaultValue="John Doe" />

  <select name="country" defaultValue="uk">
    <option value="us">United States</option>
    <option value="ca">Canada</option>
    <option value="uk">United Kingdom</option>
  </select>

  <input type="checkbox" name="subscribe" value="yes" defaultChecked />

  <button type="submit">Submit</button>
</Form>
```

:::

### Checkbox inputs

When working with checkboxes, you may want to add an explicit `value` attribute such as `value="1"`. Without a value attribute, checked checkboxes will submit as `"on"`, which some server-side validation rules may not recognize as a proper boolean value.

### Slot props

The `<Form>` component exposes reactive state and helper methods through its default slot, giving you access to form processing state, errors, and utility functions.

:::tabs key:frameworks

== Vue

```vue
<template>
  <Form
    action="/users"
    method="post"
    #default="{
      errors,
      hasErrors,
      processing,
      progress,
      wasSuccessful,
      recentlySuccessful,
      setError,
      clearErrors,
      resetAndClearErrors,
      defaults,
      isDirty,
      reset,
      submit,
    }"
  >
    <input type="text" name="name" />

    <div v-if="errors.name">
      {{ errors.name }}
    </div>

    <button type="submit" :disabled="processing">
      {{ processing ? 'Creating...' : 'Create User' }}
    </button>

    <div v-if="wasSuccessful">User created successfully!</div>
  </Form>
</template>
```

== React

```jsx
<Form action="/users" method="post">
  {({
    errors,
    hasErrors,
    processing,
    progress,
    wasSuccessful,
    recentlySuccessful,
    setError,
    clearErrors,
    resetAndClearErrors,
    defaults,
    isDirty,
    reset,
    submit,
  }) => (
    <>
      <input type="text" name="name" />

      {errors.name && <div>{errors.name}</div>}

      <button type="submit" disabled={processing}>
        {processing ? 'Creating...' : 'Create User'}
      </button>

      {wasSuccessful && <div>User created successfully!</div>}
    </>
  )}
</Form>
```

== Svelte 4

```svelte
<Form
  action="/users"
  method="post"
  let:errors
  let:hasErrors
  let:processing
  let:progress
  let:wasSuccessful
  let:recentlySuccessful
  let:setError
  let:clearErrors
  let:resetAndClearErrors
  let:defaults
  let:isDirty
  let:reset
  let:submit
>
  <input type="text" name="name" />

  {#if errors.name}
    <div>{errors.name}</div>
  {/if}

  <button type="submit" disabled={processing}>
    {processing ? 'Creating...' : 'Create User'}
  </button>

  {#if wasSuccessful}
    <div>User created successfully!</div>
  {/if}
</Form>
```

== Svelte 5

```svelte
<Form action="/users" method="post">
  {#snippet children({
    errors,
    hasErrors,
    processing,
    progress,
    wasSuccessful,
    recentlySuccessful,
    setError,
    clearErrors,
    resetAndClearErrors,
    defaults,
    isDirty,
    reset,
    submit,
  })}
    <input type="text" name="name" />

    {#if errors.name}
      <div>{errors.name}</div>
    {/if}

    <button type="submit" disabled={processing}>
      {processing ? 'Creating...' : 'Create User'}
    </button>

    {#if wasSuccessful}
      <div>User created successfully!</div>
    {/if}
  {/snippet}
</Form>
```

:::

#### `defaults` method

@available_since core=2.1.1

The `defaults` method allows you to update the form's default values to match the current field values. When called, subsequent `reset()` calls will restore fields to these new defaults, and the `isDirty` property will track changes from these updated defaults. Unlike `useForm`, this method accepts no arguments and always uses all current form values.

#### `errors` object

The `errors` object uses dotted notation for nested fields, allowing you to display validation messages for complex form structures.

:::tabs key:frameworks

== Vue

```vue
<Form action="/users" method="post" #default="{ errors }">
  <input type="text" name="user.name" />
  <div v-if="errors['user.name']">{{ errors['user.name'] }}</div>
</Form>
```

== React

```jsx
<Form action="/users" method="post">
  {({ errors }) => (
    <>
      <input type="text" name="user.name" />
      {errors['user.name'] && <div>{errors['user.name']}</div>}
    </>
  )}
</Form>
```

== Svelte 4

```svelte
<Form action="/users" method="post" let:errors>
  <input type="text" name="user.name" />
  {#if errors['user.name']}
    <div>{errors['user.name']}</div>
  {/if}
</Form>
```

== Svelte 5

```svelte
<Form action="/users" method="post">
  {#snippet children({ errors })}
    <input type="text" name="user.name" />
    {#if errors['user.name']}
      <div>{errors['user.name']}</div>
    {/if}
  {/snippet}
</Form>
```

:::

### Props and options

In addition to `action` and `method`, the `<Form>` component accepts several props. Many of them are identical to the options available in Inertia's [visit options](/guide/manual-visits).

:::tabs key:frameworks

== Vue

```vue
<Form
  action="/profile"
  method="put"
  error-bag="profile"
  query-string-array-format="indices"
  :headers="{ 'X-Custom-Header': 'value' }"
  :show-progress="false"
  :transform="(data) => ({ ...data, timestamp: Date.now() })"
  :invalidate-cache-tags="['users', 'dashboard']"
  disable-while-processing
  :options="{
    preserveScroll: true,
    preserveState: true,
    preserveUrl: true,
    replace: true,
    only: ['users', 'flash'],
    except: ['secret'],
    reset: ['page'],
  }"
>
  <input type="text" name="name" />
  <button type="submit">Update</button>
</Form>
```

Some props are intentionally grouped under `options` instead of being top-level to avoid confusion. For example, `only`, `except`, and `reset` relate to _partial reloads_, not _partial submissions_. The general rule: top-level props are for the form submission itself, while `options` control how Inertia handles the subsequent visit.

When setting the `disable-while-processing` prop, the `Form` component will add the `inert` attribute to the HTML `form` tag while the form is processing to prevent user interaction.

== React

```jsx
<Form
  action="/profile"
  method="put"
  errorBag="profile"
  queryStringArrayFormat="indices"
  headers={{ 'X-Custom-Header': 'value' }}
  showProgress={false}
  transform={(data) => ({ ...data, timestamp: Date.now() })}
  invalidateCacheTags={['users', 'dashboard']}
  disableWhileProcessing
  options={{
    preserveScroll: true,
    preserveState: true,
    preserveUrl: true,
    replace: true,
    only: ['users', 'flash'],
    except: ['secret'],
    reset: ['page'],
  }}
>
  <input type="text" name="name" />
  <button type="submit">Update</button>
</Form>
```

Some props are intentionally grouped under `options` instead of being top-level to avoid confusion. For example, `only`, `except`, and `reset` relate to _partial reloads_, not _partial submissions_. The general rule: top-level props are for the form submission itself, while `options` control how Inertia handles the subsequent visit.

When setting the `disableWhileProcessing` prop, the `Form` component will add the `inert` attribute to the HTML `form` tag while the form is processing to prevent user interaction.

== Svelte 4|Svelte 5

```svelte
<Form
  action="/profile"
  method="put"
  errorBag="profile"
  queryStringArrayFormat="indices"
  headers={{ 'X-Custom-Header': 'value' }}
  showProgress={false}
  transform={(data) => ({ ...data, timestamp: Date.now() })}
  invalidateCacheTags={['users', 'dashboard']}
  disableWhileProcessing
  options={{
    preserveScroll: true,
    preserveState: true,
    preserveUrl: true,
    replace: true,
    only: ['users', 'flash'],
    except: ['secret'],
    reset: ['page'],
  }}
>
  <input type="text" name="name" />
  <button type="submit">Update</button>
</Form>
```

Some props are intentionally grouped under `options` instead of being top-level to avoid confusion. For example, `only`, `except`, and `reset` relate to _partial reloads_, not _partial submissions_. The general rule: top-level props are for the form submission itself, while `options` control how Inertia handles the subsequent visit.

When setting the `disableWhileProcessing` prop, the `Form` component will add the `inert` attribute to the HTML `form` tag while the form is processing to prevent user interaction.

:::

To style the form while it's processing, you can target the inert form in the following ways.

:::tabs key:css

== Tailwind 4

```html
<form
  action="/profile"
  method="put"
  disableWhileProcessing
  className="inert:opacity-50 inert:pointer-events-none"
>
  {/* Your form fields here */}
</form>
```

== CSS

```css
form[inert] {
  opacity: 0.5;
  pointer-events: none;
}
```

:::

### Events

The `<Form>` component emits all the standard visit [events](/guide/events) for form submissions.

:::tabs key:frameworks

== Vue

```vue
<Form
  action="/users"
  method="post"
  @before="handleBefore"
  @start="handleStart"
  @progress="handleProgress"
  @success="handleSuccess"
  @error="handleError"
  @finish="handleFinish"
  @cancel="handleCancel"
  @cancelToken="handleCancelToken"
>
  <input type="text" name="name" />
  <button type="submit">Create User</button>
</Form>
```

== React

```jsx
<Form
  action="/users"
  method="post"
  onCancelToken={handleCancelToken}
  onBefore={handleBefore}
  onStart={handleStart}
  onProgress={handleProgress}
  onCancel={handleCancel}
  onSuccess={handleSuccess}
  onError={handleError}
  onFinish={handleFinish}
>
  <input type="text" name="name" />
  <button type="submit">Create User</button>
</Form>
```

== Svelte 4

```svelte
<Form
  action="/users"
  method="post"
  on:cancelToken={handleCancelToken}
  on:before={handleBefore}
  on:start={handleStart}
  on:progress={handleProgress}
  on:cancel={handleCancel}
  on:success={handleSuccess}
  on:error={handleError}
  on:finish={handleFinish}
>
  <input type="text" name="name" />
  <button type="submit">Create User</button>
</Form>
```

== Svelte 5

```svelte
<Form
  action="/users"
  method="post"
  onCancelToken={handleCancelToken}
  onBefore={handleBefore}
  onStart={handleStart}
  onProgress={handleProgress}
  onCancel={handleCancel}
  onSuccess={handleSuccess}
  onError={handleError}
  onFinish={handleFinish}
>
  <input type="text" name="name" />
  <button type="submit">Create User</button>
</Form>
```

:::

### Resetting the Form

@available_since core=2.1.2

The `Form` component provides several attributes that allow you to reset the form after a submission.

`resetOnSuccess` may be used to reset the form after a successful submission.

:::tabs key:frameworks

== Vue

```vue
<!-- Reset the entire form on success -->
<Form action="/users" method="post" resetOnSuccess>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>

<!-- Reset specific fields on success -->
<Form action="/users" method="post" :resetOnSuccess="['name']">
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>
```

== React

```jsx
// Reset the entire form on success
<Form action="/users" method="post" resetOnSuccess>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>

// Reset specific fields on success
<Form action="/users" method="post" resetOnSuccess={['name']}>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>
```

== Svelte 4|Svelte 5

```svelte
<!-- Reset the entire form on success -->
<Form action="/users" method="post" resetOnSuccess>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>

<!-- Reset specific fields on success -->
<Form action="/users" method="post" resetOnSuccess={['name']}>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>
```

:::

`resetOnError` may be used to reset the form after errors.

:::tabs key:frameworks

== Vue

```vue
<!-- Reset the entire form on success -->
<Form action="/users" method="post" resetOnError>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>

<!-- Reset specific fields on success -->
<Form action="/users" method="post" :resetOnError="['name']">
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>
```

== React

```jsx
// Reset the entire form on success
<Form action="/users" method="post" resetOnError>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>

// Reset specific fields on success
<Form action="/users" method="post" resetOnError={['name']}>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>
```

== Svelte 4|Svelte 5

```svelte
<!-- Reset the entire form on success -->
<Form action="/users" method="post" resetOnError>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>

<!-- Reset specific fields on success -->
<Form action="/users" method="post" resetOnError={['name']}>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>
```

:::

### Setting new default values

@available_since core=2.1.2

The `Form` component provides the `setDefaultsOnSuccess` attribute to set the current form values as the new defaults after a successful submission.

:::tabs key:frameworks

== Vue

```vue
<Form action="/users" method="post" setDefaultsOnSuccess>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>
```

== React

```jsx
<Form action="/users" method="post" setDefaultsOnSuccess>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>
```

== Svelte 4|Svelte 5

```svelte
<Form action="/users" method="post" setDefaultsOnSuccess>
  <input type="text" name="name" />
  <input type="email" name="email" />
  <button type="submit">Submit</button>
</Form>
```

:::

### Dotted key notation

The `<Form>` component supports dotted key notation for creating nested objects from flat input names. This provides a convenient way to structure form data.

:::tabs key:frameworks

== Vue

```vue
<Form action="/users" method="post">
  <input type="text" name="user.name" />
  <input type="text" name="user.skills[]" />
  <input type="text" name="address.street" />
  <button type="submit">Submit</button>
</Form>
```

== React

```jsx
<Form action="/users" method="post">
  <input type="text" name="user.name" />
  <input type="text" name="user.skills[]" />
  <input type="text" name="address.street" />
  <button type="submit">Submit</button>
</Form>
```

== Svelte 4|Svelte 5

```svelte
<Form action="/users" method="post">
  <input type="text" name="user.name" />
  <input type="text" name="user.skills[]" />
  <input type="text" name="address.street" />
  <button type="submit">Submit</button>
</Form>
```

:::

The example above would generate the following data structure.

```json
{
  "user": {
    "name": "John Doe",
    "skills": ["JavaScript"]
  },
  "address": {
    "street": "123 Main St"
  }
}
```

If you need literal dots in your field names (not as nested object separators), you can escape them using backslashes.

:::tabs key:frameworks

== Vue

```vue
<Form action="/config" method="post">
  <input type="text" name="app\.name" />
  <input type="text" name="settings.theme\.mode" />
  <button type="submit">Save</button>
</Form>
```

== React

```jsx
<Form action="/config" method="post">
  <input type="text" name="app\.name" />
  <input type="text" name="settings.theme\.mode" />
  <button type="submit">Save</button>
</Form>
```

== Svelte 4|Svelte 5

```svelte
<Form action="/config" method="post">
  <input type="text" name="app\.name" />
  <input type="text" name="settings.theme\.mode" />
  <button type="submit">Save</button>
</Form>
```

:::

The example above would generate the following data structure.

```json
{
  "app.name": "My Application",
  "settings": {
    "theme.mode": "dark"
  }
}
```

### Programmatic access

You can access the form's methods programmatically using refs. This provides an alternative to
[slot props](#slot-props) when you need to trigger form actions from outside the form.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { ref } from 'vue'
import { Form } from '@inertiajs/vue3'

const formRef = ref()

const handleSubmit = () => {
  formRef.value.submit()
}
</script>

<template>
  <Form ref="formRef" action="/users" method="post">
    <input type="text" name="name" />
    <button type="submit">Submit</button>
  </Form>

  <button @click="handleSubmit">Submit Programmatically</button>
</template>
```

== React

```jsx
import { useRef } from 'react'
import { Form } from '@inertiajs/react'

export default function CreateUser() {
  const formRef = useRef()

  const handleSubmit = () => {
    formRef.current.submit()
  }

  return (
    <>
      <Form ref={formRef} action="/users" method="post">
        <input type="text" name="name" />
        <button type="submit">Submit</button>
      </Form>

      <button onClick={handleSubmit}>Submit Programmatically</button>
    </>
  )
}
```

== Svelte 4|Svelte 5

```svelte
<script>
  import { Form } from '@inertiajs/svelte'

  let formRef

  function handleSubmit() {
    formRef.submit()
  }
</script>

<Form bind:this={formRef} action="/users" method="post">
  <input type="text" name="name" />
  <button type="submit">Submit</button>
</Form>

<button on:click={handleSubmit}>Submit Programmatically</button>
```

:::

In React and Vue, refs provide access to all form methods and reactive state. In Svelte, refs expose only methods, so reactive state like isDirty and errors should be accessed via [slot props](#slot-props) instead.

## Form helper

In addition to the `<Form>` component, Inertia also provides a `useForm` helper for when you need programmatic control over your form's data and submission behavior.

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

### Form errors

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

### Resetting the Form

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

### Setting new default values

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

### Form field change tracking

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

### Canceling Form submissions

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

### Form data and history state

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

## Server-side responses

When using Inertia, you don't typically inspect form responses client-side like you would with traditional XHR/fetch requests. Instead, your server-side route or controller issues a [redirect](/guide/redirects) response after processing the form, often redirecting to a success page.

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

This redirect-based approach works with all form submission methods: the `<Form>` component, `useForm` helper, and manual router submissions. It makes handling Inertia forms feel very similar to classic server-side form submissions.

## Server-side validation

Both the `<Form>` component and `useForm` helper automatically handle server-side validation errors. When your server returns validation errors, they're automatically available in the `errors` object without any additional configuration.

Unlike traditional XHR/fetch requests where you might check for a `422` status code, Inertia handles validation errors as part of its redirect-based flow, just like classic server-side form submissions, but without the full page reload.

For a complete guide on validation error handling, including error bags and advanced scenarios, see the [validation documentation](/guide/validation).

## Manual form submissions

It's also possible to submit forms manually using Inertia's `router` methods directly, without using the `<Form>` component or `useForm` helper:

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

## File uploads

When making requests or form submissions that include files, Inertia will automatically convert the request data into a `FormData` object. This works with the `<Form>` component, `useForm` helper, and manual router submissions.

For more information on file uploads, including progress tracking, see the [file uploads documentation](/guide/file-uploads).

## XHR / fetch submissions

Using Inertia to submit forms works great for the vast majority of situations. However, in the event that you need more control over the form submission, you're free to make plain XHR or `fetch` requests instead, using the library of your choice.
