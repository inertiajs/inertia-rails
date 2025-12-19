# Flash Data

@available_since rails=master core=2.3.3

Sometimes you may wish to send one-time data to your frontend that shouldn't reappear when users navigate through browser history. Unlike regular props, flash data isn't persisted in history state, making it ideal for success messages, newly created IDs, or other temporary values.

## Flashing Data

You may flash data using the `inertia_flash` controller method.

```ruby
class UsersController < ApplicationController
  def create
    user = User.new(user_params)

    if user.save
      inertia_flash[:message] = 'User created successfully!'

      redirect_to users_url
    else
      redirect_to new_user_url, inertia: { errors: user.errors }
    end
  end
end
```

Passing props to `redirect_to` is also supported.

```ruby
redirect_to users_url, inertia: { flash: { new_user_id: user.id } }
```

Flash data is scoped to the current request. The middleware automatically persists it to the session when redirecting. After the flash data is sent to the client, it is cleared and will not appear in subsequent requests.

## Accessing Flash Data

Flash data is available on `page.flash`. You may also listen for the global `flash` event or use the `onFlash` callback.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { usePage } from '@inertiajs/vue3'

const page = usePage()
</script>

<template>
  <div v-if="page.flash.toast" class="toast">
    {{ page.flash.toast.message }}
  </div>
</template>
```

== React

```jsx
import { usePage } from '@inertiajs/react'

export default function Layout({ children }) {
  const { flash } = usePage()

  return (
    <>
      {flash.toast && <div className="toast">{flash.toast.message}</div>}
      {children}
    </>
  )
}
```

== Svelte 4|Svelte 5

```svelte
<script>
  import { page } from '@inertiajs/svelte'
</script>

{#if $page.flash.toast}
  <div class="toast">{$page.flash.toast.message}</div>
{/if}
```

:::

## The onFlash Callback

You may use the `onFlash` callback to handle flash data when making requests.

:::tabs key:frameworks

== Vue

```js
import { router } from '@inertiajs/vue3'

router.post('/users', data, {
  onFlash: ({ newUserId }) => {
    form.userId = newUserId
  },
})
```

== React

```js
import { router } from '@inertiajs/react'

router.post('/users', data, {
  onFlash: ({ newUserId }) => {
    form.userId = newUserId
  },
})
```

== Svelte

```js
import { router } from '@inertiajs/svelte'

router.post('/users', data, {
  onFlash: ({ newUserId }) => {
    form.userId = newUserId
  },
})
```

:::

## Global Flash Event

You may use the global `flash` event to handle flash data in a central location, such as a layout component. For more information on events, see the [events documentation](/guide/events).

:::tabs key:frameworks

== Vue

```js
import { router } from '@inertiajs/vue3'

router.on('flash', (event) => {
  if (event.detail.flash.toast) {
    showToast(event.detail.flash.toast)
  }
})
```

== React

```js
import { router } from '@inertiajs/react'

router.on('flash', (event) => {
  if (event.detail.flash.toast) {
    showToast(event.detail.flash.toast)
  }
})
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.on('flash', (event) => {
  if (event.detail.flash.toast) {
    showToast(event.detail.flash.toast)
  }
})
```

:::

Native browser events are also supported.

:::tabs key:frameworks

== Vue

```js Vue icon="vuejs"
document.addEventListener('inertia:flash', (event) => {
  console.log(event.detail.flash)
})
```

== React

```js
document.addEventListener('inertia:flash', (event) => {
  console.log(event.detail.flash)
})
```

== Svelte 4|Svelte 5

```js
document.addEventListener('inertia:flash', (event) => {
  console.log(event.detail.flash)
})
```

:::

The `flash` event is not cancelable. During [partial reloads](/guide/partial-reloads), it only fires if the flash data has changed.

## Client-Side Flash

You may set flash data on the client without a server request using the `router.flash()` method. Values are merged with existing flash data.

:::tabs key:frameworks

== Vue

```js
import { router } from '@inertiajs/vue3'

router.flash('foo', 'bar')
router.flash({ foo: 'bar' })
```

== React

```js
import { router } from '@inertiajs/react'

router.flash('foo', 'bar')
router.flash({ foo: 'bar' })
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.flash('foo', 'bar')
router.flash({ foo: 'bar' })
```

:::

A callback may also be passed to access the current flash data or replace it entirely.

:::tabs key:frameworks

== Vue

```js
import { router } from '@inertiajs/vue3'

router.flash((current) => ({ ...current, bar: 'baz' }))
router.flash(() => ({}))
```

== React

```js
import { router } from '@inertiajs/react'

router.flash((current) => ({ ...current, bar: 'baz' }))
router.flash(() => ({}))
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.flash((current) => ({ ...current, bar: 'baz' }))
router.flash(() => ({}))
```

:::

## TypeScript

You may configure the flash data type globally using TypeScript's declaration merging.

```ts
// global.d.ts
declare module '@inertiajs/core' {
  export interface InertiaConfig {
    flashDataType: {
      toast?: {
        type: 'success' | 'error'
        message: string
      }
    }
  }
}
```

With this configuration, `page.flash.toast` will be properly typed as `{ type: "success" | "error"; message: string } | undefined`.
