# CSRF protection

## Making requests

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

== Svelte 4|Svelte 5

```js
import { page, router } from '@inertiajs/svelte'

router.post('/users', {
  _token: $page.props.csrf_token,
  name: 'John Doe',
  email: 'john.doe@example.com',
})
```

:::

You can even use Inertia's [shared data](/guide/shared-data.md) functionality to automatically include the `csrf_token` with each response.

However, a better approach is to use the CSRF functionality already built into [axios](https://github.com/axios/axios) for this. Axios is the HTTP library that Inertia uses under the hood.

Axios automatically checks for the existence of an `XSRF-TOKEN` cookie. If it's present, it will then include the token in an `X-XSRF-TOKEN` header for any requests it makes.

The easiest way to implement this is using server-side middleware. Simply include the `XSRF-TOKEN` cookie on each response, and then verify the token using the `X-XSRF-TOKEN` header sent in the requests from axios. (That's basically what `inertia_rails` does).

> [!NOTE]
>
> `X-XSRF-TOKEN` header only works for [Inertia requests](/guide/the-protocol#inertia-responses). If you want to send a normal request you can use `X-CSRF-TOKEN` instead.

## Handling mismatches

When a CSRF token mismatch occurs, Rails raises the `ActionController::InvalidAuthenticityToken` error. Since that isn't a valid Inertia response, the error is shown in a modal.

Obviously, this isn't a great user experience. A better way to handle these errors is to return a redirect back to the previous page, along with a flash message that the page expired. This will result in a valid Inertia response with the flash message available as a prop which you can then display to the user. Of course, you'll need to share your [flash messages](/guide/shared-data.md#flash-messages) with Inertia for this to work.

You may modify your application's exception handler to automatically redirect the user back to the page they were previously on while flashing a message to the session. To accomplish this, you may use the `rescue_from` method in your `ApplicationController`.

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActionController::InvalidAuthenticityToken, with: :inertia_page_expired_error

  inertia_share flash: -> { flash.to_hash }

  private

  def inertia_page_expired_error
    redirect_back_or_to('/', allow_other_host: false, notice: "The page expired, please try again.")
  end
end
```

The end result is a much better experience for your users. Instead of seeing the error modal, the user is instead presented with a message that the page "expired" and are asked to try again.
