# Deferred Props

@available_since rails=3.6.0 core=2.0.0

Inertia's deferred props feature allows you to defer the loading of certain page data until after the initial page render. This can be useful for improving the perceived performance of your app by allowing the initial page render to happen as quickly as possible.

## Server Side

To defer a prop, you can use the `InertiaRails.defer` method when returning your response. This method receives a callback that returns the prop data. The callback will be executed in a separate request after the initial page render.

```ruby
class UsersController < ApplicationController
  def index
    render inertia: {
      users: -> { User.all },
      roles: -> { Role.all },
      permissions: InertiaRails.defer { Permission.all },
    }
  end
end
```

### Grouping Requests

By default, all deferred props get fetched in one request after the initial page is rendered, but you can choose to fetch data in parallel by grouping props together using the `group` option with the `InertiaRails.defer` method.

```ruby
class UsersController < ApplicationController
  def index
    render inertia: {
      users: -> { User.all },
      roles: -> { Role.all },
      permissions: InertiaRails.defer { Permission.all },
      teams: InertiaRails.defer(group: 'attributes') { Team.all },
      projects: InertiaRails.defer(group: 'attributes') { Project.all },
      tasks: InertiaRails.defer(group: 'attributes') { Task.all },
    }
  end
end
```

In the example above, the `teams`, `projects`, and `tasks` props will be fetched in one request, while the `permissions` prop will be fetched in a separate request in parallel. Group names are arbitrary strings and can be anything you choose.

### Combining with Mergeable Props

Deferred props can be combined with mergeable props. You can learn more about this feature in the [Merging props](/guide/merging-props) section.

## Client Side

On the client side, Inertia provides the `Deferred` component to help you manage deferred props. This component will automatically wait for the specified deferred props to be available before rendering its children.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { Deferred } from '@inertiajs/vue3'
</script>

<template>
  <Deferred data="permissions">
    <template #fallback>
      <div>Loading...</div>
    </template>

    <div v-for="permission in permissions">
      <!-- ... -->
    </div>
  </Deferred>
</template>
```

== React

```jsx
import { Deferred } from '@inertiajs/react'

export default () => (
  <Deferred data="permissions" fallback={<div>Loading...</div>}>
    <PermissionsChildComponent />
  </Deferred>
)
```

== Svelte

```svelte
<script>
  import { Deferred } from '@inertiajs/svelte'

  let { permissions } = $props()
</script>

<Deferred data="permissions">
  {#snippet fallback()}
    <div>Loading...</div>
  {/snippet}

  {#each permissions as permission}
    <!-- ... -->
  {/each}
</Deferred>
```

:::

## Multiple Deferred Props

If you need to wait for multiple deferred props to become available, you can specify an array to the `data` prop.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { Deferred } from '@inertiajs/vue3'
</script>

<template>
  <Deferred :data="['teams', 'users']">
    <template #fallback>
      <div>Loading...</div>
    </template>

    <!-- Props are now loaded -->
  </Deferred>
</template>
```

== React

```jsx
import { Deferred } from '@inertiajs/react'

export default () => (
  <Deferred data={['teams', 'users']} fallback={<div>Loading...</div>}>
    <ChildComponent />
  </Deferred>
)
```

== Svelte

```svelte
<script>
  import { Deferred } from '@inertiajs/svelte'

  let { teams, users } = $props()
</script>

<Deferred data={['teams', 'users']}>
  {#snippet fallback()}
    <div>Loading...</div>
  {/snippet}

  <!-- Props are now loaded -->
</Deferred>
```

:::

## Reloading Indicator

@available_since core=3.0.0

When deferred props are being reloaded via a partial reload, the `Deferred` component exposes a `reloading` boolean through its slot. This allows you to show a loading indicator while still displaying the previously loaded data.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { Deferred } from '@inertiajs/vue3'
</script>

<template>
  <Deferred data="permissions" #default="{ reloading }">
    <template #fallback>
      <div>Loading...</div>
    </template>

    <div :class="{ 'opacity-50': reloading }">
      <div v-for="permission in permissions">
        <!-- ... -->
      </div>
    </div>
  </Deferred>
</template>
```

== React

```jsx
import { Deferred } from '@inertiajs/react'

export default () => (
  <Deferred data="permissions" fallback={<div>Loading...</div>}>
    {({ reloading }) => (
      <div className={reloading ? 'opacity-50' : ''}>
        <PermissionsChildComponent />
      </div>
    )}
  </Deferred>
)
```

== Svelte

```svelte
<script>
  import { Deferred } from '@inertiajs/svelte'

  let { permissions } = $props()
</script>

<Deferred data="permissions">
  {#snippet fallback()}
    <div>Loading...</div>
  {/snippet}

  {#snippet children({ reloading })}
    <div class:opacity-50={reloading}>
      {#each permissions as permission}
        <!-- ... -->
      {/each}
    </div>
  {/snippet}
</Deferred>
```

:::

The `reloading` prop is `false` on the initial load and becomes `true` whenever a partial reload is in progress for the deferred keys. It returns to `false` once the reload completes.

## Error Handling

@available_since rails=master core=3.1.0

By default, exceptions thrown while resolving a deferred prop result in an error response. You may instruct Inertia to rescue these exceptions by passing `rescue: true` to `InertiaRails.defer`.

```ruby
class UsersController < ApplicationController
  def index
    render inertia: {
      permissions: InertiaRails.defer(rescue: true) { current_user.permissions },
    }
  end
end
```

When a deferred prop is rescued, it is omitted from the response and the exception is reported via Rails's [Error Reporter](https://guides.rubyonrails.org/error_reporting.html#using-the-error-reporter).

> [!NOTE]
> To catch errors reliably, Inertia serializes the rescued prop (by calling `as_json` on its value) within the rescued scope. This means lazy values such as `ActiveRecord::Relation`s have their queries executed, and serialization errors are caught too — not just exceptions raised directly within the block.

On the client side, you may provide a `rescue` slot to the `Deferred` component to render a fallback UI when a prop fails to load.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { Deferred, router } from '@inertiajs/vue3'
</script>
<template>
  <Deferred data="permissions">
    <template #fallback>
      <div>Loading...</div>
    </template>
    <template #rescue="{ reloading }">
      <div>
        <p>Failed to load permissions.</p>
        <button
          :disabled="reloading"
          @click="router.reload({ only: ['permissions'] })"
        >
          Retry
        </button>
      </div>
    </template>
    <div v-for="permission in permissions">
      <!-- ... -->
    </div>
  </Deferred>
</template>
```

== React

```jsx
import { Deferred, router } from '@inertiajs/react'

export default () => (
  <Deferred
    data="permissions"
    fallback={<div>Loading...</div>}
    rescue={({ reloading }) => (
      <div>
        <p>Failed to load permissions.</p>
        <button
          disabled={reloading}
          onClick={() => router.reload({ only: ['permissions'] })}
        >
          Retry
        </button>
      </div>
    )}
  >
    <PermissionsChildComponent />
  </Deferred>
)
```

== Svelte

```svelte
<script>
  import { Deferred, router } from '@inertiajs/svelte'
  let { permissions } = $props()
</script>

<Deferred data="permissions">
  {#snippet fallback()}
    <div>Loading...</div>
  {/snippet}
  {#snippet rescue({ reloading })}
    <div>
      <p>Failed to load permissions.</p>
      <button
        disabled={reloading}
        onclick={() => router.reload({ only: ['permissions'] })}>Retry</button
      >
    </div>
  {/snippet}
  {#each permissions as permission}
    <!-- ... -->
  {/each}
</Deferred>
```

:::

The rescue state is preserved until you explicitly reload the rescued prop. The `rescue` slot receives a `reloading` boolean, allowing you to disable the retry button or show a loading indicator while the reload is in progress.

## Combining with Once Props

@available_since rails=3.15.0 core=2.2.20

You may pass the `once: true` argument to a deferred prop to ensure the data is resolved only once and remembered by the client across subsequent navigations.

```ruby
class DashboardController < ApplicationController
  def index
    render inertia: {
      stats: InertiaRails.defer(once: true) { Stats.generate },
    }
  end
end
```

For more information on once props, see the [once props](/guide/once-props) documentation.

## Combining with Caching

@available_since rails=3.21.0

You may pass the `cache` option to a deferred prop to cache the resolved value on the server side. On cache hits, the block is not evaluated.

```ruby
class DashboardController < ApplicationController
  def index
    render inertia: {
      feed: InertiaRails.defer(cache: { key: 'feed', expires_in: 5.minutes }, group: 'feed') { current_user.feed },
    }
  end
end
```

For more information on cache keys and options, see the [cached props](/guide/cached-props) documentation.
