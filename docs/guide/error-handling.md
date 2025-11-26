# Error handling

## Development

One of the advantages to working with a robust server-side framework is the built-in exception handling you get for free. The challenge is, if you're making an XHR request (which Inertia does) and you hit a server-side error, you're typically left digging through the network tab in your browser's devtools to diagnose the problem.

Inertia solves this issue by showing all non-Inertia responses in a modal. This means you get the same beautiful error-reporting you're accustomed to, even though you've made that request over XHR.

## Dialog element

@available_since core=2.2.13

By default, Inertia displays error modals using a custom `<div>` overlay. However, you can opt-in to using the native HTML `<dialog>` element instead, which provides built-in modal functionality including backdrop handling.

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

In production you will want to return a proper Inertia error response instead of relying on the modal-driven error reporting that is present during development. To accomplish this, you'll need to update your framework's default exception handler to return a custom error page.

When building Rails applications, you can accomplish this by using the `rescue_from` method in your `ApplicationController`.

```ruby
class ApplicationController < ActionController::Base
  rescue_from StandardError, with: :inertia_error_page

  private

  def inertia_error_page(exception)
    raise exception if Rails.env.local?

    status = ActionDispatch::ExceptionWrapper.new(nil, exception).status_code

    render inertia: 'ErrorPage', props: { status: }, status:
  end
end
```

You may have noticed we're returning an `ErrorPage` page component in the example above. You'll need to actually create this component, which will serve as the generic error page for your application. Here's an example error component you can use as a starting point.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { computed } from 'vue'

const props = defineProps({ status: Number })

const title = computed(() => {
  return (
    {
      503: 'Service Unavailable',
      500: 'Server Error',
      404: 'Page Not Found',
      403: 'Forbidden',
    }[props.status] || 'Unexpected error'
  )
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
    <h1>{{ status }}: {{ title }}</h1>
    <div>{{ description }}</div>
  </div>
</template>
```

== React

```jsx
export default function ErrorPage({ status }) {
  const title =
    {
      503: 'Service Unavailable',
      500: 'Server Error',
      404: 'Page Not Found',
      403: 'Forbidden',
    }[status] || 'Unexpected error'

  const description = {
    503: 'Sorry, we are doing some maintenance. Please check back soon.',
    500: 'Whoops, something went wrong on our servers.',
    404: 'Sorry, the page you are looking for could not be found.',
    403: 'Sorry, you are forbidden from accessing this page.',
  }[status]

  return (
    <div>
      <h1>
        {status}: {title}
      </h1>
      <div>{description}</div>
    </div>
  )
}
```

== Svelte 4

```svelte
<script>
  export let status

  $: title =
    {
      503: 'Service Unavailable',
      500: 'Server Error',
      404: 'Page Not Found',
      403: 'Forbidden',
    }[status] || 'Unexpected error'

  $: description = {
    503: 'Sorry, we are doing some maintenance. Please check back soon.',
    500: 'Whoops, something went wrong on our servers.',
    404: 'Sorry, the page you are looking for could not be found.',
    403: 'Sorry, you are forbidden from accessing this page.',
  }[status]
</script>

<div>
  <h1>{status}: {title}</h1>
  <div>{description}</div>
</div>
```

== Svelte 5

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
