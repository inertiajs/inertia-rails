# Precognition

@available_since rails=3.18.0 core=2.3.0

Precognition enables real-time validation of form data without executing the full controller action. When your client-side form sends a validation request with special headers, the server runs your validations and responds with the results immediately — without saving records or triggering other side effects.

> [!NOTE]
> This page covers the **server-side** (Rails) setup. For client-side usage with the `<Form>` component and `useForm` helper, see the [forms documentation](/guide/forms#precognition). For the `useHttp` hook, see [HTTP requests](/guide/http-requests#precognition).

Unlike Laravel, Rails doesn't have a standard params validation layer, so Inertia Rails provides a small DIY kit for those who want to use Precognition.

## Basic usage

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

Both methods accept an ActiveModel-like object (calls `valid?` automatically) or an errors hash, and optionally a block to [transform the errors](#transforming-error-keys) before they're sent:

- For valid data, responds with `204 No Content` with `Precognition: true` and `Precognition-Success: true` headers
- For invalid data, responds with `422 Unprocessable Entity` with errors as JSON and a `Precognition: true` header

## One call per action

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

## Module-level API

`InertiaRails.precognition!` works the same way as the controller method but can be called from anywhere in the request cycle — form objects, service objects, or any Ruby code:

```ruby
InertiaRails.precognition!(@user)
```

This is useful when you want to handle precognition outside the controller.

## Form objects

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

## Other validation libraries

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

## Preventing side effects

Since precognition requests reuse your existing controller actions, it's important to place the `precognition!` call **before** any side-effect-producing code (saving records, sending emails, calling external APIs, enqueuing jobs). The `precognition!` method halts the action on precognition requests, so any code after it only runs during real form submissions.

You can also enable [`precognition_prevent_writes`](/guide/configuration#precognition_prevent_writes) to automatically block database writes during precognition requests as an extra safety net.

## Field-specific validation

Inertia's client-side form helper can request validation of specific fields using the `Precognition-Validate-Only` header. The server automatically filters the errors to only include the requested fields.

## Transforming error keys

Both `precognition!` and `precognition` accept an optional block to transform the errors hash before it's sent to the client. This is useful when your form fields are wrapped in an envelope using `name="user.name"`, `name="user[name]`, or via the `transform` prop. In those cases, the server error keys need to match:

```ruby
def create
  @user = User.new(user_params)
  precognition!(@user) { |errors| { user: errors } }

  if @user.save
    redirect_to @user
  else
    redirect_back_or_to new_user_path, inertia: { errors: { user: @user.errors } }
  end
end
```

Nested hashes are automatically flattened to dot-notated keys. `{ user: { name: [...] } }` becomes `{ "user.name" => [...] }` in the response, matching the format the client expects when looking up errors for a field named `user.name`. The block only runs when there are errors; on a successful validation, the 204 response is sent without calling the block.

The block runs before field-level filtering, so `Precognition-Validate-Only: user.name` correctly finds the flattened key.

When you pass nested errors to `redirect_to` with `inertia: { errors: ... }`, inertia adds a copy of the errors with flattened keys. The original nested structure is preserved alongside flat dot-notated copies. This means `{ user: @user.errors }` in the redirect produces both `errors.user.email_address` (nested) and `errors['user.email_address']` (flat) on the client, so `invalid('user.email_address')` works consistently whether the error came from a precognition request or a full form submission.

## Using `transform` with precognition

When using the `<Form>` component with a `transform` prop that wraps data under a key (e.g., `transform={(data) => ({ user: data })}`), the field names passed to `validate()` must match the keys in the **transformed** data structure, not the input `name` attributes.

This is because `validate('name')` looks up the value using the field name in the transformed data. If the transform wraps inputs under `user`, the transformed data is `{ user: { name: '...' } }`, and `validate('name')` won't find a value at the top level.

To work around this, you have two options:

**Option 1: Use dotted input names instead of a transform**

Use `name="user.name"` (or `name="user[name]"`) input attributes. The `<Form>` component automatically converts these into a nested `{ user: { name: '...' } }` structure without needing a transform, so `validate('user.name')` will correctly find the value. Server error keys must match (e.g., `user.name`) — use a block to prefix them:

```ruby
precognition!(@user) { |errors| { user: errors } }
```

See [Transforming error keys](#transforming-error-keys) for details.

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

== Svelte

```js
const form = useForm({
  name: '',
  email: '',
}).withPrecognition('post', '/users')

form.transform((data) => ({ user: data }))
```

:::
