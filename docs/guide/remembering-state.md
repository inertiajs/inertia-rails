# Remembering State

When navigating browser history, Inertia restores pages using prop data cached in history state. However, Inertia does not restore local page component state since this is beyond its reach. This can lead to outdated pages in your browser history.

For example, if a user partially completes a form, then navigates away, and then returns back, the form will be reset and their work will be lost.

To mitigate this issue, you can tell Inertia which local component state to save in the browser history.

## Saving Local State

To save local component state to the history state, use the `useRemember` feature to tell Inertia which data it should remember.

:::tabs key:frameworks

== Vue

```js
import { useRemember } from '@inertiajs/vue3'

const form = useRemember({
  first_name: null,
  last_name: null,
})
```

== React

```jsx
import { useRemember } from '@inertiajs/react'

export default function Profile() {
  const [formState, setFormState] = useRemember({
    first_name: null,
    last_name: null,
    // ...
  })

  // ...
}
```

== Svelte

```js
import { useRemember } from '@inertiajs/svelte'

const form = useRemember({
  first_name: null,
  last_name: null,
})

// ...
```

:::

Now, whenever your local `form` state changes, Inertia will automatically save this data to the history state and will also restore it on history navigation.

## Multiple Components

If your page contains multiple components that use the remember functionality provided by Inertia, you need to provide a unique key for each component so that Inertia knows which data to restore to each component.

:::tabs key:frameworks

== Vue

```js
import { useRemember } from '@inertiajs/vue3'

const form = useRemember(
  {
    first_name: null,
    last_name: null,
  },
  'Users/Create',
)
```

== React

```jsx
import { useRemember } from '@inertiajs/react'

export default function Profile() {
  const [formState, setFormState] = useRemember(
    {
      first_name: null,
      last_name: null,
    },
    'Users/Create',
  )
}
```

== Svelte

```js
import { page, useRemember } from '@inertiajs/svelte'

const form = useRemember(
  {
    first_name: null,
    last_name: null,
  },
  'Users/Create',
)
```

:::

If you have multiple instances of the same component on the page using the remember functionality, be sure to also include a unique key for each component instance, such as a model identifier.

:::tabs key:frameworks

== Vue

```js
import { useRemember } from '@inertiajs/vue3'

const props = defineProps({ user: Object })

const form = useRemember(
  {
    first_name: null,
    last_name: null,
  },
  `Users/Edit:${props.user.id}`,
)
```

== React

```jsx
import { useRemember } from '@inertiajs/react'

export default function Profile() {
  const [formState, setFormState] = useRemember(
    {
      first_name: props.user.first_name,
      last_name: props.user.last_name,
    },
    `Users/Edit:${this.user.id}`,
  )
}
```

== Svelte

```js
import { page, useRemember } from '@inertiajs/svelte'

const form = useRemember(
  {
    first_name: page.props.user.first_name,
    last_name: page.props.user.last_name,
  },
  `Users/Edit:${page.props.user.id}`,
)
```

:::

## Form Helper

If you're using the [Inertia form helper](/guide/forms#form-helper), you can pass a unique form key as the first argument when instantiating your form. This will cause the form data and errors to automatically be remembered.

:::tabs key:frameworks

== Vue

```js
import { useForm } from '@inertiajs/vue3'

const form = useForm('CreateUser', data)
const form = useForm(`EditUser:${props.user.id}`, data)
```

== React

```js
import { useForm } from '@inertiajs/react'

const form = useForm('CreateUser', data)
const form = useForm(`EditUser:${user.id}`, data)
```

== Svelte

```js
import { useForm } from '@inertiajs/svelte'

const form = useForm('CreateUser', data)
const form = useForm(`EditUser:${user.id}`, data)
```

:::

You may [exclude specific fields](/guide/forms#excluding-fields) from being remembered using the `dontRemember()` method. This is useful for sensitive fields like passwords that should not be stored in history state.

## Manually Saving State

The `useRemember` hook watches for data changes and automatically saves those changes to the history state. Then, Inertia will restore the data on page load.

However, it's also possible to manage this manually using the underlying `remember()` and `restore()` methods exposed by Inertia.

:::tabs key:frameworks

== Vue

```js
import { router } from '@inertiajs/vue3'

// Save local component state to history state
router.remember(data, 'my-key')

// Restore local component state from history state
let data = router.restore('my-key')
```

== React

```js
import { router } from '@inertiajs/react'

// Save local component state to history state
router.remember(data, 'my-key')

// Restore local component state from history state
let data = router.restore('my-key')
```

== Svelte

```js
import { router } from '@inertiajs/svelte'

// Save local component state to history state
router.remember(data, 'my-key')

// Restore local component state from history state
let data = router.restore('my-key')
```

:::

> [!WARNING]
> Some browsers limit the number of `history.replaceState()` calls allowed
> within a short time period. Inertia catches this error and logs it to the
> console, but the state update will be lost. Avoid calling `router.remember()`
> too frequently, and consider debouncing or batching state updates in
> high-frequency scenarios.
