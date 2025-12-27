# Deferred props

@available_since rails=3.6.0 core=2.0.0

Inertia's deferred props feature allows you to defer the loading of certain page data until after the initial page render. This can be useful for improving the perceived performance of your app by allowing the initial page render to happen as quickly as possible.

## Server side

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

### Grouping requests

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

### Combining with mergeable props

Deferred props can be combined with mergeable props. You can learn more about this feature in the [Merging props](/guide/merging-props) section.

## Client side

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

== Svelte 4

```svelte
<script>
  import { Deferred } from '@inertiajs/svelte'
  export let permissions
</script>

<Deferred data="permissions">
  <svelte:fragment slot="fallback">
    <div>Loading...</div>
  </svelte:fragment>

  {#each permissions as permission}
    <!-- ... -->
  {/each}
</Deferred>
```

== Svelte 5

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

== Svelte 4

```svelte
<script>
  import { Deferred } from '@inertiajs/svelte'
  export let teams
  export let users
</script>

<Deferred data={['teams', 'users']}>
  <svelte:fragment slot="fallback">
    <div>Loading...</div>
  </svelte:fragment>

  <!-- Props are now loaded -->
</Deferred>
```

== Svelte 5

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
