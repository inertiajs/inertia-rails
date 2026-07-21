# Forms and Envelopes

The format for the `name` attributes of the fields in an Inertia `<Form />` impacts the following features:

* Strong parameters in the controller
* The Inertia `errors` object that is passed to `redirect_to` when there are validation errors
* The format of errors in a `precognition` call in a controller
* The `errors()` function in the `<Form />` component and `useForm` helper
* The `validate()` and `invalid()` functions when using Precognition for real-time form validation

The Inertia scaffold generator creates flat attribute names:
```jsx
<Form>
  <input type="email" name="email_address" />
</Form>
```
In contrast, a form in a regular Rails application created with `form_for` wraps those keys in an _envelope_.
```html
<form ...>
  <input type="email" name="user[email_address]" />
</form>
```
Why does Inertia use flat keys? And what if we wanted to use envelopes with Inertia forms? In this article, we'll answer those questions by reviewing the features listed above, with and without an envelope. We'll also look at a couple shortcuts for adding an envelope (along with their gotchas).

The short version: you may freely choose to use or avoid envelopes, but Inertia uses flat attribute names everywhere for conciseness and easy consistency.

## Envelope-less Inertia Forms

A `<Form />` component with flat keys, and using Precognition, naturally has consistent keys across the `name` attributes and calls to `validate()`, `invalid()`, and `errors`:
```jsx
<Form>
  {({ errors, invalid, validate }) => (
    <>
      <input
        type="email"
        name="email_address"
        onBlur={() => validate('email_address')}
      />
      {invalid('email_address') && <p>{errors.email_address}</p>}
    </>
  )}
</Form>
```
Here is the corresponding controller action:
```ruby
def create
  @user = User.new(user_params)
  precognition!(@user)

  if @user.save
    redirect_to user_path(@user)
  else
    redirect_to new_user_path, inertia: { errors: @user.errors }
  end
end

def user_params
  params.permit(:email_address, :password, ...)
end
```

Since there is no `user` envelope on the submitted data, this controller:
1. Uses `params.permit(...)` instead of `params.expect(:user).permit(...)`
2. Passes `@user.errors` directly to the `inertia.errors` option in the redirect when there are validation errors
3. Requires no [additional formatting](/guide/precognition#transforming-error-keys) of the errors returned from the `precognition!` call.

What would it take to wrap the form data in an envelope?

## Enveloped Inertia Forms

Here's the same `<Form />` component with an explicit envelope added to the `name` attributes. The key names remain consistent across the `name` attributes and calls to `validate()`, `invalid()`, and `errors`:
```jsx
<Form>
  {({ errors, invalid, validate }) => (
    <>
      <input
        type="email"
        name="user[email_address]"
        onBlur={() => validate('user.email_address')}
      />
      {invalid('user.email_address') && <p>{errors['user.email_address']}</p>}
    </>
  )}
</Form>
```
Now the corresponding controller must consistently wrap the data in an envelope when there are errors:
```ruby
def create
  @user = User.new(user_params)
  precognition!(@user) {|errors| { user: errors } }

  if @user.save
    redirect_to user_path(@user)
  else
    redirect_to new_user_path, inertia: { errors: { user: @user.errors } }
  end
end

def user_params
  params.expect(:user).permit(:email_address, :password, ...)
end
```
Here we see:
1. Strong parameters include the `expect(:user)` syntax
2. The `precognition!` call wraps errors in a `user` envelope — they are automatically flattened to `{ "user.email_address" => [...] }` before being sent to the client
3. Validation errors in the redirect are also wrapped in a `user` envelope. Inertia automatically copies flat dot-notated keys from any nested errors hash, so `errors['user.email_address']` and `invalid('user.email_address')` work consistently for both precognition validation and full form submission.

The code is still explicit and consistent, although it is more verbose than our envelope-less example. There are a couple shortcuts worth exploring.

## The `transform` Shortcut

The `<Form />` component includes a `transform` prop that allows us to write flat `name` attributes and add an envelope before submitting the form:
```jsx
<Form transform={(data) => ({ user: data })}>
  {({ errors, invalid, validate }) => (
    <>
      <input
        type="email"
        name="email_address"
        onBlur={() => validate('user.email_address')}
      />
      {invalid('user.email_address') && <p>{errors['user.email_address']}</p>}
    </>
  )}
</Form>
```
Precognition sends _transformed_ data to the server, so `validate()` must use the same dot-notated key that we had in the _Enveloped Inertia Forms_ section. And this same key will look up the errors returned by the server, so the controller still needs to wrap the errors in an envelope. Inertia copies and flattens the error keys, ensuring `errors['user.email_address']` and `invalid('user.email_address')` work after both precognition validation and full form submission.

We've made the `name` attributes more concise, but the rest of the verbose code remains. In fact, the controller hasn't changed at all. Additionally, we've created a mismatch between the `name` attributes and the shape of the data that's used both on the server and in the `validate()`, `invalid()`, and `errors` calls.

What if we tackled the envelope on the server instead?

## The `wrap_parameters` Shortcut

Rails ships with a `wrap_parameters` controller method that copies request parameters for a model into an enveloped hash. It's enabled by default on JSON requests, and Inertia `<Form />` submissions are usually in JSON format. So, this `<Form />` will Just Work™ with the controller below.
```jsx
<Form>
  <input type="email" name="email_address" />
  ...
</Form>
```

```ruby
def create
  @user = User.new(user_params)
  precognition!(@user)

  if @user.save
    redirect_to user_path(@user)
  else
    redirect_to new_user_path, inertia: { errors: @user.errors }
  end
end

# `.expect` works because `wrap_parameters` created a `user` envelope
def user_params
  params.expect(:user).permit(:email_address, :password, ...)
end
```
At first glance, this appears to elegantly add an envelope while keeping the code concise. However, there are a few caveats.

First, `wrap_parameters` works by inferring the model based on the controller name and calling `.attribute_names` on that model. If our controller were named something other than `UsersController`, we would need to explicitly configure the model in `wrap_parameters`. Secondly, if our form sends a key not listed in `.attribute_names` (e.g. data for an associated record), `wrap_parameters` will not automatically include it in the enveloped data. Finally, if the `<Form />` includes a file input, Inertia (helpfully!) [changes the request format](/guide/file-uploads) to `multipart/form-data`. Rails does not, by default, configure `wrap_parameters` for `multipart/form-data` requests.

For these reasons, `wrap_parameters` will likely require explicit configuration for some controllers in a real-world application, should you choose to rely on it for creating envelopes.

## “Wrapping” Up

We've seen four different options for coordinating the shape of a `<Form />`'s data across an Inertia application:

* Flat `name` attributes with no data envelope
* Data with an explicit envelope in both the `name` attributes and in the errors returned by the server
* Flat `name` attributes wrapped in an envelope on the client with the `transform` prop
* Flat `name` attributes wrapped in an envelope on the server with `wrap_parameters`

There's no single right answer, but now we can see why the Inertia Rails scaffold generator chooses the first option: it's concise, consistent across the client and server, and free from annoying gotchas.
