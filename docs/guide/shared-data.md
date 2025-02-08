# Shared data

Sometimes you need to access specific pieces of data on numerous pages within your application. For example, you may need to display the current user in the site header. Passing this data manually in each response across your entire application is cumbersome. Thankfully, there is a better option: shared data.

## Sharing data

The `inertia_share` method allows you to define data that will be available to all controller actions, automatically merging with page-specific props.

### Basic Usage

```ruby
class EventsController < ApplicationController
  # Static sharing: Data is evaluated immediately
  inertia_share app_name: Rails.configuration.app_name

  # Dynamic sharing: Data is evaluated at render time
  inertia_share do
    {
      user: current_user,
      notifications: current_user&.unread_notifications_count
    } if user_signed_in?
  end

  # Alternative syntax for single dynamic values
  inertia_share total_users: -> { User.count }
end
```

### Conditional Sharing

You can control when data is shared using Rails-style controller filters. The `inertia_share` method supports these filter options:

- `only`: Share data for specific actions
- `except`: Share data for all actions except specified ones
- `if`: Share data when condition is true
- `unless`: Share data when condition is false

```ruby
class EventsController < ApplicationController
  # Share user data only when authenticated
  inertia_share if: :user_signed_in? do
    {
      user: {
        name: current_user.name,
        email: current_user.email,
        role: current_user.role
      }
    }
  end

  # Share data only for specific actions
  inertia_share only: [:index, :show] do
    {
      meta: {
        last_updated: Time.current,
        version: "1.0"
      }
    }
  end
end
```

> [!NOTE]
> Shared data should be used sparingly as all shared data is included with every response.

> [!NOTE]
> Page props and shared data are merged together, so be sure to namespace your shared data appropriately to avoid collisions.

## Accessing shared data

Once you have shared the data server-side, you will be able to access it within any of your pages or components. Here's an example of how to access shared data in a layout component.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { computed } from 'vue'
import { usePage } from '@inertiajs/vue3'

const page = usePage()

const user = computed(() => page.props.auth.user)
</script>

<template>
  <main>
    <header>You are logged in as: {{ user.name }}</header>
    <article>
      <slot />
    </article>
  </main>
</template>
```

== React

```jsx
import { usePage } from '@inertiajs/react'

export default function Layout({ children }) {
  const { auth } = usePage().props

  return (
    <main>
      <header>You are logged in as: {auth.user.name}</header>
      <article>{children}</article>
    </main>
  )
}
```

== Svelte 4|Svelte 5

```svelte
<script>
  import { page } from '@inertiajs/svelte'
</script>

<main>
  <header>
    You are logged in as: {$page.props.auth.user.name}
  </header>
  <article>
    <slot />
  </article>
</main>
```

:::

# Flash messages

Another great use-case for shared data is flash messages. These are messages stored in the session only for the next request. For example, it's common to set a flash message after completing a task and before redirecting to a different page.

Here's a simple way to implement flash messages in your Inertia applications. First, share the flash message on each request.

```ruby
class ApplicationController < ActionController::Base
  inertia_share flash: -> { flash.to_hash }
end
```

Next, display the flash message in a frontend component, such as the site layout.

:::tabs key:frameworks
== Vue

```vue
<template>
  <main>
    <header></header>
    <article>
      <div v-if="$page.props.flash.alert" class="alert">
        {{ $page.props.flash.alert }}
      </div>
      <div v-if="$page.props.flash.notice" class="notice">
        {{ $page.props.flash.notice }}
      </div>
      <slot />
    </article>
    <footer></footer>
  </main>
</template>
```

== React

```jsx
import { usePage } from '@inertiajs/react'

export default function Layout({ children }) {
  const { flash } = usePage().props

  return (
    <main>
      <header></header>
      <article>
        {flash.alert && <div className="alert">{flash.alert}</div>}
        {flash.notice && <div className="notice">{flash.notice}</div>}
        {children}
      </article>
      <footer></footer>
    </main>
  )
}
```

== Svelte 4|Svelte 5

```svelte
<script>
  import { page } from '@inertiajs/svelte'
</script>

<main>
  <header></header>
  <article>
    {#if $page.props.flash.alert}
      <div class="alert">{$page.props.flash.alert}</div>
    {/if}
    {#if $page.props.flash.notice}
      <div class="notice">{$page.props.flash.notice}</div>
    {/if}
    <slot />
  </article>
  <footer></footer>
</main>
```

:::

## Deep Merging Shared Data

By default, Inertia will shallow merge data defined in an action with the shared data. You might want a deep merge. Imagine using shared data to represent defaults you'll override sometimes.

```ruby
class ApplicationController
  inertia_share do
    { basketball_data: { points: 50, rebounds: 100 } }
  end
end
```

Let's say we want a particular action to change only part of that data structure. The renderer accepts a `deep_merge` option:

```ruby
class CrazyScorersController < ApplicationController
  def index
    render inertia: 'CrazyScorersComponent',
      props: { basketball_data: { points: 100 } },
      deep_merge: true
  end
end

# The renderer will send this to the frontend:
{
  basketball_data: {
    points: 100,
    rebounds: 100,
  }
}
```

Deep merging can be set as the project wide default via the `InertiaRails` configuration:

```ruby
# config/initializers/some_initializer.rb
InertiaRails.configure do |config|
  config.deep_merge_shared_data = true
end

```

If deep merging is enabled by default, it's possible to opt out within the action:

```ruby
class CrazyScorersController < ApplicationController
  inertia_share do
    {
      basketball_data: {
        points: 50,
        rebounds: 10,
      }
    }
  end

  def index
    render inertia: 'CrazyScorersComponent',
      props: { basketball_data: { points: 100 } },
      deep_merge: false
  end
end

# Even if deep merging is set by default, since the renderer has `deep_merge: false`, it will send a shallow merge to the frontend:
{
  basketball_data: {
    points: 100,
  }
}
```
