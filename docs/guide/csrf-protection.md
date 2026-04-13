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

## Stateless Controllers in Hybrid Applications

When Inertia coexists with sessionless controllers in the same Rails application — such as token-authenticated API endpoints, webhook receivers, or any controller that does not rely on the session — it's important to configure CSRF protection correctly on those controllers.

A common pattern is to reach for `skip_forgery_protection`:

```ruby
class StatelessController < ApplicationController
  skip_forgery_protection
end
```

However, `skip_forgery_protection` only removes the `verify_authenticity_token` before-action — it does not disable the CSRF infrastructure. Rails' `protect_against_forgery?` still returns `true`, so InertiaRails' after-action fires and calls `form_authenticity_token`, which reads and writes `session[:_csrf_token]`. This causes a session record to be loaded (and created, if one doesn't exist) for every request, even though the controller has explicitly opted out of CSRF.

The correct approach is to use the `:null_session` strategy instead:

```ruby
class StatelessController < ApplicationController
  protect_from_forgery with: :null_session
end
```

With `:null_session`, Rails runs `verify_authenticity_token` but handles the expected absence of a CSRF token by substituting a `NullSessionHash` for the real session. This causes `protect_against_forgery?` to return `false` for the remainder of that request — InertiaRails' after-action is correctly skipped, and no session I/O occurs.

This is also what the [Rails source recommends](https://github.com/rails/rails/blob/main/actionpack/lib/action_controller/metal/request_forgery_protection.rb) for sessionless endpoints within an otherwise session-based application:

> "APIs may want to disable this behavior since they are typically designed to be state-less [...] One way to achieve this is to use the `:null_session` strategy instead, which allows unverified requests to be handled, but with an empty session."

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
