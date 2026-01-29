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

### Inheritance and Shared Data

Shared data defined in parent controllers is automatically inherited by child controllers. Child controllers can also override or add to the shared data:

```ruby
# Parent controller
  class ApplicationController < ActionController::Base
  inertia_share app_name: 'My App', version: '1.0'
end

# Child controller
class UsersController < ApplicationController
  # Inherits app_name and version, adds/overrides auth
  inertia_share auth: -> { { user: current_user } }
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

## Sharing Once Props

@available_since rails=3.15.0 core=2.2.20

You may share data that is resolved only once and remembered by the client across subsequent navigations using [once props](/guide/once-props).

```ruby
class ApplicationController < ActionController::Base
  inertia_share countries: InertiaRails.once { Country.all }
end
```

For more information on once props, see the [once props](/guide/once-props) documentation.

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

## Flash Data

@available_since rails=master core=2.3.3

For one-time notifications like toast messages or success alerts, you may use [flash data](/guide/flash-data). Unlike shared data, flash data is not persisted in the browser's history state, so it won't reappear when navigating through history.

## TypeScript

When using TypeScript, you can configure global types for shared props using declaration merging. See the [TypeScript documentation](/guide/typescript#shared-page-props) for more information.

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
    render inertia: {
      basketball_data: { points: 100 }
    }, deep_merge: true
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
    render inertia: {
      basketball_data: { points: 100 }
    }, deep_merge: false
  end
end

# Even if deep merging is set by default, since the renderer has `deep_merge: false`, it will send a shallow merge to the frontend:
{
  basketball_data: {
    points: 100,
  }
}
```
