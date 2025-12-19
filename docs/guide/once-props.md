# Once Props

@available_since rails=3.15.0 core=2.2.20

Some data rarely changes, is expensive to compute, or is simply large. Rather than including this data in every response, you may use _once props_. These props are remembered by the client and reused on subsequent pages that include the same prop. This makes them ideal for [shared data](/guide/shared-data).

## Creating Once Props

To create a once prop, use the `InertiaRails.once` method when returning your response. This method receives a block that returns the prop data.

```ruby
class BillingController < ApplicationController
  def index
    render inertia: {
      plans: InertiaRails.once { Plan.all },
    }
  end
end
```

After the client has received this prop, subsequent requests will skip resolving the block and exclude the prop from the response. The client only remembers once props while navigating between pages that include them.

Navigating to a page without the once prop will forget the remembered value, and it will be resolved again on the next page that has it. In practice, this is rarely an issue since once props are typically used as shared data or within a specific section of your application.

## Forcing a Refresh

You may force a once prop to be refreshed using the `fresh` parameter.

```ruby
class BillingController < ApplicationController
  def index
    render inertia: {
      plans: InertiaRails.once(fresh: true) { Plan.all },
    }
  end
end
```

## Refreshing from the Client

You may refresh a once prop from the client-side using a [partial reload](/guide/partial-reloads). The server will always resolve a once prop when explicitly requested.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.reload({ only: ['plans'] })
```

== React

```js
import { router } from '@inertiajs/react'

router.reload({ only: ['plans'] })
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.reload({ only: ['plans'] })
```

:::

## Expiration

You may set an expiration time using the `expires_in` parameter. This parameter accepts an `ActiveSupport::Duration` or an integer (seconds). The prop will be refreshed on a subsequent visit after the expiration time has passed.

```ruby
class DashboardController < ApplicationController
  def index
    render inertia: {
      plans: InertiaRails.once(expires_in: 1.day) { Plan.all },
    }
  end
end
```

## Custom Keys

You may assign a custom key to the prop using the `key` parameter. This is useful when you want to share data across multiple pages while using different prop names.

```ruby
class TeamsController < ApplicationController
  def index
    render inertia: {
      memberRoles: InertiaRails.once(key: 'roles') { Role.all },
    }
  end

  def invite
    render inertia: {
      availableRoles: InertiaRails.once(key: 'roles') { Role.all },
    }
  end
end
```

Both pages share the same underlying data because they use the same custom key, so the prop is only resolved for whichever page you visit first.

## Sharing Once Props

You may share once props globally using the `inertia_share` controller method.

```ruby
class ApplicationController < ActionController::Base
  inertia_share countries: InertiaRails.once { Country.all }
end
```

## Prefetching

Once props are compatible with [prefetching](/guide/prefetching). The client automatically includes any remembered once props in prefetched responses, so navigating to a prefetched page will already have the once props available.

Prefetched pages containing an expired once prop will be invalidated from the cache.

## Combining with Other Prop Types

The `once` option can be passed to [deferred](/guide/deferred-props), [merge](/guide/merging-props), and [optional](/guide/partial-reloads#lazy-data-evaluation) props.

```ruby
class DashboardController < ApplicationController
  def index
    render inertia: {
      memberRoles: InertiaRails.once(key: 'roles') { Role.all },
      permissions: InertiaRails.defer(once: true) { Permission.all },
      activity: InertiaRails.merge(once: true) { @user.recent_activity },
      categories: InertiaRails.optional(once: true) { Category.all },
    }
  end
end
```
