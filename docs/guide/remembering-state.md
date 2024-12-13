# Remembering state

When navigating browser history, Inertia restores pages using prop data cached in history state. However, Inertia does not restore local page component state since this is beyond its reach. This can lead to outdated pages in your browser history.

For example, if a user partially completes a form, then navigates away, and then returns back, the form will be reset and their work will be lost.

To mitigate this issue, you can tell Inertia which local component state to save in the browser history.

## Saving local state

To save local component state to the history state, use the "useRemember" hook to tell Inertia which data it should remember.

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

```js
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

== Svelte 4|Svelte 5

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

## Multiple components

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

```js
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

== Svelte 4|Svelte 5

```js
import { page, useRemember } from '@inertiajs/svelte'

let form = useRemember(
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

```js
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

== Svelte 4|Svelte 5

```js
import { page, useRemember } from '@inertiajs/svelte'

let form = useRemember(
  {
    first_name: $page.props.user.first_name,
    last_name: $page.props.user.last_name,
  },
  `Users/Edit:${$page.props.user.id}`,
)
```

:::

## Form helper

If you're using the Inertia [form helper](/guide/forms.md#form-helper), you can pass a unique form key as the first argument when instantiating your form. This will cause the form data and errors to automatically be remembered.

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

== Svelte 4|Svelte 5

```js
import { useForm } from '@inertiajs/svelte'

const form = useForm('CreateUser', data)
const form = useForm(`EditUser:${user.id}`, data)
```

:::

## Manually saving state

The `useRemember` hook watches for data changes and automatically saves them to the history state. When navigating back to the page, Inertia will restore this data.

However, it's also possible to manage this manually using the underlying `remember()` and `restore()` methods in Inertia.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

// Save local component state to history state...
router.remember(data, 'my-key')

// Restore local component state from history state...
let data = router.restore('my-key')
```

== React

```js
import { router } from '@inertiajs/react'

// Save local component state to history state...
router.remember(data, 'my-key')

// Restore local component state from history state...
let data = router.restore('my-key')
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

// Save local component state to history state...
router.remember(data, 'my-key')

// Restore local component state from history state...
let data = router.restore('my-key')
```

:::
