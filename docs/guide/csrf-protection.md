# CSRF Protection

## Making Requests

Inertia's Rails adapter automatically includes the proper CSRF token when making requests via Inertia or Axios. Therefore, **no additional configuration is required**.

However, if you need to handle CSRF protection manually, one approach is to include the CSRF token as a prop on every response. You can then use the token when making Inertia requests.

:::tabs key:frameworks
== Vue

```js
import { router, usePage } from '@inertiajs/vue3'

const page = usePage()

router.post('/users', {
  _token: page.props.csrf_token,
  name: 'John Doe',
  email: 'john.doe@example.com',
})
```

== React

```js
import { router, usePage } from '@inertiajs/react'

const props = usePage().props

router.post('/users', {
  _token: props.csrf_token,
  name: 'John Doe',
  email: 'john.doe@example.com',
})
```

== Svelte

```js
import { page, router } from '@inertiajs/svelte'

router.post('/users', {
  _token: page.props.csrf_token,
  name: 'John Doe',
  email: 'john.doe@example.com',
})
```

:::

You can even use Inertia's [shared data](/guide/shared-data) functionality to automatically include the `csrf_token` with each response.

A better approach is to use Inertia's built-in XSRF token handling. Inertia's HTTP client automatically checks for the existence of an `XSRF-TOKEN` cookie and, when present, includes the token in an `X-XSRF-TOKEN` header for every request it makes.

The easiest way to implement this is using server-side middleware. Simply include the `XSRF-TOKEN` cookie on each response, and then verify the token using the `X-XSRF-TOKEN` header sent in the requests from Inertia.

You may customize the cookie and header names via the `http` option in `createInertiaApp`.

@available_since core=3.0.0

```js
createInertiaApp({
  http: {
    xsrfCookieName: 'MY-XSRF-TOKEN',
    xsrfHeaderName: 'X-MY-XSRF-TOKEN',
  },
  // ...
})
```

## Handling Mismatches

When a CSRF token mismatch occurs, Rails raises the `ActionController::InvalidAuthenticityToken` error which results in a `419` error page. Since that isn't a valid Inertia response, the error is shown in a modal.

Obviously, this isn't a great user experience. A better way to handle these errors is to return a redirect back to the previous page, along with a flash message that the page expired. This will result in a valid Inertia response with the flash message available as a prop which you can then display to the user. Of course, you'll need to share your [flash messages](/guide/shared-data#flash-messages) with Inertia for this to work.

You may modify your application's exception handler to automatically redirect the user back to the page they were previously on while flashing a message to the session. To accomplish this, you can use Rails' `rescue_from` (or by overriding `handle_unverified_request`) in your base controller.

```ruby
class InertiaController < ApplicationController
  rescue_from ActionController::InvalidAuthenticityToken do
    redirect_back_or_to root_path, alert: "The page expired, please try again."
  end
end
```

The end result is a much better experience for your users. Instead of seeing the error modal, the user is instead presented with a message that the page "expired" and are asked to try again.
