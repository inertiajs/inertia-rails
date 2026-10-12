# Error Handling

## Development

One of the advantages to working with a robust server-side framework is the built-in exception handling you get for free.

The challenge is, if you're making an XHR request (which Inertia does) and you hit a server-side error, you're typically left digging through the network tab in your browser's devtools to diagnose the problem.

Inertia solves this issue by showing all non-Inertia responses in a modal. This means you get the same beautiful error-reporting you're accustomed to, even though you've made that request over XHR.

For applications using a [Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) that restricts inline styles, you may pass a `nonce` to `createInertiaApp()` to permit the inline styles the error modal injects. See [Content Security Policy](/guide/client-side-setup#content-security-policy) for details.

## Dialog element

@available_since core=2.2.13

By default, Inertia < 3.x displays error modals using a custom `<div>` overlay. However, you can opt-in to using the native HTML `<dialog>` element instead, which provides built-in modal functionality including backdrop handling.

To enable this, configure the `future.useDialogForErrorModal` option in your [application defaults](/guide/client-side-setup#configuring-defaults).

```js
createInertiaApp({
  // resolve, setup, etc.
  defaults: {
    future: {
      useDialogForErrorModal: true,
    },
  },
})
```

## Production

@available_since rails=master

In production, you want a styled error page instead of the modal Inertia shows during development. Inertia Rails provides an exceptions app that renders error pages with a controller you write. Set it in `config/application.rb`:

```ruby
# config/application.rb
config.exceptions_app = InertiaRails::ExceptionsApp.new(controller: 'ErrorsController')
```

```ruby
# app/controllers/errors_controller.rb
class ErrorsController < ApplicationController
  include InertiaRails::ErrorPage

  def show
    render inertia: 'ErrorPage', props: { status: }
  end
end
```

Rails calls the [exceptions app](https://guides.rubyonrails.org/configuring.html#config-exceptions-app) for every exception your app doesn't rescue, routing errors included. When an HTML or Inertia request fails with a 403, 404, 500, or 503 status, the exceptions app calls the `show` action of your controller. Inertia requests get the page as JSON, so the error page replaces the current page without a full reload.

Other responses stay the same as with Rails' default exceptions app:

- JSON and other non-HTML requests get a body like `{ "status": 404, "error": "Not Found" }` in the requested format.
- Statuses without an Inertia page, such as 422, get the matching file from `public/`, like `public/422.html`.

`InertiaRails::ErrorPage` sets the response status to the error's status before any callback runs, so `render` uses it and `status` returns it. Inertia Rails checks the controller when your app boots, so a typo in its name or a missing `include` raises an error right away.

The error controller is a regular controller, so error pages get your layout and `inertia_share` data.

> [!NOTE]
> In development, Rails shows its debug page instead, because `config.consider_all_requests_local` is `true`. To preview your error pages, set it to `false` in `config/environments/development.rb`.

### Error page example

You'll need to create the `ErrorPage` component. Here's an example you may use as a starting point.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { computed } from 'vue'

const props = defineProps({ status: Number })

const title = computed(() => {
  return {
    503: '503: Service Unavailable',
    500: '500: Server Error',
    404: '404: Page Not Found',
    403: '403: Forbidden',
  }[props.status]
})

const description = computed(() => {
  return {
    503: 'Sorry, we are doing some maintenance. Please check back soon.',
    500: 'Whoops, something went wrong on our servers.',
    404: 'Sorry, the page you are looking for could not be found.',
    403: 'Sorry, you are forbidden from accessing this page.',
  }[props.status]
})
</script>

<template>
  <div>
    <h1>{{ title }}</h1>
    <div>{{ description }}</div>
  </div>
</template>
```

== React

```jsx
export default function ErrorPage({ status }) {
  const title = {
    503: '503: Service Unavailable',
    500: '500: Server Error',
    404: '404: Page Not Found',
    403: '403: Forbidden',
  }[status]

  const description = {
    503: 'Sorry, we are doing some maintenance. Please check back soon.',
    500: 'Whoops, something went wrong on our servers.',
    404: 'Sorry, the page you are looking for could not be found.',
    403: 'Sorry, you are forbidden from accessing this page.',
  }[status]

  return (
    <div>
      <h1>{title}</h1>
      <div>{description}</div>
    </div>
  )
}
```

== Svelte

```svelte
<script>
  let { status } = $props()

  const title = {
    503: '503: Service Unavailable',
    500: '500: Server Error',
    404: '404: Page Not Found',
    403: '403: Forbidden',
  }

  const description = {
    503: 'Sorry, we are doing some maintenance. Please check back soon.',
    500: 'Whoops, something went wrong on our servers.',
    404: 'Sorry, the page you are looking for could not be found.',
    403: 'Sorry, you are forbidden from accessing this page.',
  }
</script>

<div>
  <h1>{title[status]}</h1>
  <div>{description[status]}</div>
</div>
```

:::

### Skipping callbacks

The error controller runs every callback it inherits. A callback that redirects sends visitors away from the error page, and when one raises, Rails responds with a plain-text 500 instead. Skip such callbacks in the error controller:

```ruby
class ErrorsController < ApplicationController
  include InertiaRails::ErrorPage

  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized

  # ...
end
```

Look out for these in particular:

- Devise's `authenticate_user!` gives signed-out visitors a plain-text 500, because the exceptions app runs outside the Warden middleware.
- Pundit's `verify_authorized` raises, because the error page doesn't authorize anything.
- Rails' `rate_limit` raises once a visitor goes over the limit. You can't skip it by name, so declare it in the controllers that need it, or pass it `unless: -> { is_a?(ErrorsController) }`.

### Customizing the page

The `show` action can render any component with any props:

```ruby
def show
  component = status == 404 ? 'NotFound' : 'ErrorPage'

  render inertia: component, props: { status:, request_id: request.request_id }
end
```

The exception that caused the error is available as `request.env['action_dispatch.exception']`.

Don't read `params` in the error controller or its callbacks. They come from the failed request, and when its body doesn't parse, reading them raises again and Rails responds with a plain-text 500. When the query string doesn't parse, the exceptions app serves the file from `public/` instead of calling your controller.

### Choosing statuses

Pass `statuses:` to choose which statuses get an Inertia page:

```ruby
config.exceptions_app = InertiaRails::ExceptionsApp.new(
  controller: 'ErrorsController',
  statuses: [403, 404, 422, 429, 500, 503]
)
```

Rails maps exceptions to statuses with `config.action_dispatch.rescue_responses`. Add your own exceptions there, for example to show the 403 page when Pundit denies access:

```ruby
# config/application.rb
config.action_dispatch.rescue_responses['Pundit::NotAuthorizedError'] = :forbidden
```

### Limitations

Rails calls the exceptions app from the `ActionDispatch::ShowExceptions` middleware, which sits above the cookie, session, flash, and Content Security Policy middleware. Error page responses don't pass through them:

- Error pages can't set cookies. A visitor whose first request fails gets neither a session nor an `XSRF-TOKEN` cookie.
- Session changes aren't saved. A flash message or validation errors shown on an error page appear again on the next page, and a `clear_history` from a redirect applies to that page too.
- Error pages don't get a `Content-Security-Policy` header.
- Deferred props in your shared data make the client request the failing URL again to load them.
