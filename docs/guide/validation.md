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

In order for your server-side validation errors to be available client-side, your server-side framework must share them via the `errors` prop. Inertia's Rails adapter does this automatically.

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
> Error bags are a Laravel-specific feature that relies on Laravel's `ViewErrorBag` system. In Rails, this feature is typically unnecessary because:
>
> - Forms submit to separate controller actions, so only one set of errors is returned per request
> - The [form helper](/guide/forms.md) automatically scopes validation errors to each form instance
>
> If you have multiple forms on a page, use the `useForm()` helper and each form will maintain its own isolated error state.

## Precognition

Precognition enables real-time validation of form data without executing the full controller action. When using Inertia's `useForm()` helper with the `precognitive` option, validation requests are sent to your server with special headers, and the server responds with validation results immediately.

### Basic usage

Use `precognition!` or `precognition` in your controller to handle precognition requests:

```ruby
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    precognition!(@user)

    if @user.save
      redirect_to @user
    else
      redirect_back_or_to new_user_path, inertia: { errors: @user.errors }
    end
  end
end
```

Two controller methods are available:

- **`precognition!(model_or_errors)`** — raises an exception to halt the action on precognition requests. No `return if` needed — the action simply stops. For non-precognition requests, returns `false` and continues normally.
- **`precognition(model_or_errors)`** — returns `true` if a precognition response was rendered, `false` otherwise. Use with `return if precognition(@user)` if you prefer the explicit return pattern.

Both methods accept an ActiveModel-like object (calls `valid?` automatically) or an errors hash:

- For valid data, responds with `204 No Content` with `Precognition: true` and `Precognition-Success: true` headers
- For invalid data, responds with `422 Unprocessable Entity` with errors as JSON and a `Precognition: true` header

### One call per action

You can only call `precognition!` or `precognition` once per controller action. Calling it a second time raises `InertiaRails::DoublePrecognitionError`. This is intentional — precognition validates a single form submission, so there should be exactly one validation point per action.

If you need to validate multiple models, use a [form object](#form-objects) that combines all validations into a single `valid?` call:

```ruby
# Bad — raises DoublePrecognitionError
def create
  precognition!(@user)
  precognition!(@profile) # Error!
end

# Good — validate everything in one call
def create
  form = RegistrationForm.new(params)
  precognition!(form) # Validates user + profile together
end
```

### Module-level API

`InertiaRails.precognition!` works the same way as the controller method but can be called from anywhere in the request cycle — form objects, service objects, or any Ruby code:

```ruby
InertiaRails.precognition!(@user)
```

This is useful when you want to handle precognition outside the controller.

### Form objects

When your form doesn't map directly to a single model, you can create a plain Ruby class with validations using `ActiveModel::API` and `ActiveModel::Attributes`. This gives you the same validation interface as a model:

```ruby
class RegistrationForm
  include ActiveModel::API
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :email, :string
  attribute :company_name, :string

  validates :name, :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :company_name, presence: true

  def save
    InertiaRails.precognition!(self)

    return false unless valid?

    # Create user, company, etc.
  end
end
```

Since `InertiaRails.precognition!` works from anywhere, form objects handle precognition themselves — no controller changes needed:

```ruby
class RegistrationsController < ApplicationController
  def create
    form = RegistrationForm.new(params)

    if form.save
      redirect_to form.user
    else
      redirect_back_or_to new_registration_path, inertia: { errors: form.errors }
    end
  end
end
```

### Other validation libraries

For libraries like dry-validation, pass the errors hash:

```ruby
class UsersController < ApplicationController
  def create
    result = UserContract.new.call(user_params.to_h)
    precognition!(result.errors.to_h)

    if result.success?
      @user = User.create!(result.to_h)
      redirect_to @user
    else
      redirect_back_or_to new_user_path, inertia: { errors: result.errors.to_h }
    end
  end
end
```

### Preventing side effects

Since precognition requests reuse your existing controller actions, it's important to place the `precognition!` call **before** any side-effect-producing code (saving records, sending emails, calling external APIs, enqueuing jobs). The `precognition!` method halts the action on precognition requests, so any code after it only runs during real form submissions.

You can also enable [`precognition_prevent_writes`](/guide/configuration#precognition_prevent_writes) to automatically block database writes during precognition requests as an extra safety net.

### Client-side setup

For detailed client-side usage of precognition with the `<Form>` component and `useForm` helper, see the [forms documentation](/guide/forms.md#precognition).

### Field-specific validation

Inertia's client-side form helper can request validation of specific fields using the `Precognition-Validate-Only` header. The server automatically filters the errors to only include the requested fields.

### Using `transform` with precognition

When using the `<Form>` component with a `transform` prop that wraps data under a key (e.g., `transform={(data) => ({ user: data })}`), the field names passed to `validate()` must match the keys in the **transformed** data structure, not the input `name` attributes.

This is because `validate('name')` looks up the value using the field name in the transformed data. If the transform wraps inputs under `user`, the transformed data is `{ user: { name: '...' } }`, and `validate('name')` won't find a value at the top level.

To work around this, you have two options:

**Option 1: Use dotted input names instead of a transform**

Use `name="user.name"` (or `name="user[name]"`) input attributes. The `<Form>` component automatically converts these into a nested `{ user: { name: '...' } }` structure without needing a transform, so `validate('user.name')` will correctly find the value. Note that server error keys must match (e.g., `user.name`), so you may need to prefix errors in your precognition response.

**Option 2: Use `useForm` with `withPrecognition` instead**

The `useForm` helper tracks data internally, so `validate('name')` always works regardless of transforms:

:::tabs key:frameworks

== Vue

```js
const form = useForm({
  name: '',
  email: '',
}).withPrecognition('post', '/users')

// The transform only applies to the submitted data, not the validate() lookup
form.transform((data) => ({ user: data }))
```

== React

```jsx
const form = useForm({
  name: '',
  email: '',
}).withPrecognition('post', '/users')

form.transform((data) => ({ user: data }))
```

== Svelte 4|Svelte 5

```js
const form = useForm({
  name: '',
  email: '',
}).withPrecognition('post', '/users')

$form.transform((data) => ({ user: data }))
```

:::
