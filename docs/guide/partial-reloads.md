# Partial Reloads

When making visits to the same page you are already on, it's not always necessary to re-fetch all of the page's data from the server. In fact, selecting only a subset of the data can be a helpful performance optimization if it's acceptable that some page data becomes stale. Inertia makes this possible via its "partial reload" feature.

As an example, consider a "user index" page that includes a list of users, as well as an option to filter the users by their company. On the first request to the page, both the `users` and `companies` props are passed to the page component. However, on subsequent visits to the same page (maybe to filter the users), you can request only the `users` data from the server without requesting the `companies` data. Inertia will then automatically merge the partial data returned from the server with the data it already has in memory client-side.

> [!NOTE]
> Partial reloads only work for visits made to the same page component.

## Only Certain Props

To perform a partial reload, use the `only` visit option to specify which data the server should return. This option should be an array of keys which correspond to the keys of the props.

:::tabs key:frameworks

== Vue

```js
import { router } from '@inertiajs/vue3'

router.visit(url, {
  only: ['users'],
})
```

== React

```js
import { router } from '@inertiajs/react'

router.visit(url, {
  only: ['users'],
})
```

== Svelte

```js
import { router } from '@inertiajs/svelte'

router.visit(url, {
  only: ['users'],
})
```

:::

## Except Certain Props

In addition to the `only` visit option you can also use the `except` option to specify which data the server should exclude. This option should also be an array of keys which correspond to the keys of the props.

:::tabs key:frameworks

== Vue

```js
import { router } from '@inertiajs/vue3'

router.visit(url, {
  except: ['users'],
})
```

== React

```js
import { router } from '@inertiajs/react'

router.visit(url, {
  except: ['users'],
})
```

== Svelte

```js
import { router } from '@inertiajs/svelte'

router.visit(url, {
  except: ['users'],
})
```

:::

## Router Shorthand

Since partial reloads can only be made to the same page component the user is already on, it almost always makes sense to just use the `router.reload()` method, which automatically uses the current URL.

:::tabs key:frameworks

== Vue

```js
import { router } from '@inertiajs/vue3'

router.reload({ only: ['users'] })
```

== React

```js
import { router } from '@inertiajs/react'

router.reload({ only: ['users'] })
```

== Svelte

```js
import { router } from '@inertiajs/svelte'

router.reload({ only: ['users'] })
```

:::

## Using Links

It's also possible to perform partial reloads with Inertia links using the `only` property.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <Link href="/users?active=true" :only="['users']">Show active</Link>
</template>
```

== React

```jsx
import { Link } from '@inertiajs/react'

export default () => (
  <Link href="/users?active=true" only={['users']}>
    Show active
  </Link>
)
```

== Svelte

```svelte
<script>
  import { inertia, Link } from '@inertiajs/svelte'
</script>

<a href="/users?active=true" use:inertia={{ only: ['users'] }}>Show active</a>

<Link href="/users?active=true" only={['users']}>Show active</Link>
```

:::

## Lazy Data Evaluation

For partial reloads to be most effective, be sure to also use lazy data evaluation when returning props from your server-side routes or controllers. This can be accomplished by wrapping all optional page data in a lambda.

```ruby
class UsersController < ApplicationController
  def index
    render inertia: {
      users: -> { User.all },
      companies: -> { Company.all },
    }
  end
end
```

When Inertia performs a request, it will determine which data is required and only then will it evaluate the lambda. This can significantly increase the performance of pages that contain a lot of optional data.

Additionally, Inertia provides an `InertiaRails.optional` method to specify that a prop should never be included unless explicitly requested using the `only` option:

```ruby
class UsersController < ApplicationController
  def index
    render inertia: {
      users: InertiaRails.optional { User.all },
    }
  end
end
```

> [!NOTE]
> Prior to Inertia.js v2, the method `InertiaRails.lazy` was used. It is now deprecated and has been replaced by `InertiaRails.optional`. Please update your code accordingly to ensure compatibility with the latest version.

On the inverse, you can use the `InertiaRails.always` method to specify that a prop should always be included, even if it has not been explicitly required in a partial reload.

```ruby
class UsersController < ApplicationController
  def index
    render inertia: {
      users: InertiaRails.always { User.all },
    }
  end
end
```

Here's a summary of each approach:

| Approach                                                                      | Standard Visits | Partial Reloads | Evaluated        |
| :---------------------------------------------------------------------------- | :-------------- | :-------------- | :--------------- |
| <span style="white-space: nowrap">`User.all`</span>                           | Always          | Optionally      | Always           |
| <span style="white-space: nowrap">`-> { User.all }`</span>                    | Always          | Optionally      | Only when needed |
| <span style="white-space: nowrap">`InertiaRails.optional { User.all }`</span> | Never           | Optionally      | Only when needed |
| <span style="white-space: nowrap">`InertiaRails.always { User.all }`</span>   | Always          | Always          | Always           |

## Preserving Errors

@available_since core=3.0.0

Since the Rails adapter shares errors using `InertiaRails.always`, they are included in every response, even partial reloads where no validation runs. This means an empty errors hash from the server will overwrite any existing client-side validation errors. You may use the `preserveErrors` option to keep existing errors when the server doesn't return new ones.

:::tabs key:frameworks

== Vue

```js
router.reload({
  only: ['posts'],
  preserveErrors: true,
})
```

== React

```js
router.reload({
  only: ['posts'],
  preserveErrors: true,
})
```

== Svelte

```js
router.reload({
  only: ['posts'],
  preserveErrors: true,
})
```

:::

## Combining with Once Props

@available_since rails=3.15.0 core=2.2.20

You may pass the `once: true` argument to a deferred prop to ensure the data is resolved only once and remembered by the client across subsequent navigations.

```ruby
class UsersController < ApplicationController
  def index
    render inertia: {
      users: InertiaRails.optional(once: true) { User.all },
    }
  end
end
```

For more information on once props, see the [once props](/guide/once-props) documentation.
