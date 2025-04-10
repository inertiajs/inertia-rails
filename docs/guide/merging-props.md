# Merging props

By default, Inertia overwrites props with the same name when reloading a page. However, there are instances, such as pagination or infinite scrolling, where that is not the desired behavior. In these cases, you can merge props instead of overwriting them.

## Server side

> `deep_merge` requires `@inertiajs/core` v2.0.8 or higher, and `inertia_rails` v3.8.0 or higher.

To specify that a prop should be merged, use the `merge` or `deep_merge` method on the prop's value.

Use `merge` for merging simple arrays, and `deep_merge` for handling nested objects that include arrays or complex structures, such as pagination objects.

```ruby
class UsersController < ApplicationController
  include Pagy::Backend

  def index
    pagy, records = pagy(User.all)

    render inertia: {
      # simple array:
      users: InertiaRails.merge { records.as_json(...) },
      # pagination object:
      data: InertiaRails.deep_merge {
        {
          records: records.as_json(...),
          pagy: pagy_metadata(pagy)
        }
      }
    }
  end
end
```

On the client side, Inertia detects that this prop should be merged. If the prop returns an array, it will append the response to the current prop value. If it's an object, it will merge the response with the current prop value. If you have opted to `deepMerge`, Inertia ensures a deep merge of the entire structure.

**Of note:** During the merging process, if the value is an array, the incoming items will be _appended_ to the existing array, not merged by index.

You can also combine [deferred props](/guide/deferred-props) with mergeable props to defer the loading of the prop and ultimately mark it as mergeable once it's loaded.

```ruby
class UsersController < ApplicationController
  include Pagy::Backend

  def index
    pagy, records = pagy(User.all)

    render inertia: {
      # simple array:
      users: InertiaRails.defer(merge: true) { records.as_json(...) },
      # pagination object:
      data: InertiaRails.defer(deep_merge: true) {
        {
          records: records.as_json(...),
          pagy: pagy_metadata(pagy)
        }
      }
    }
  end
end
```

## Resetting props

On the client side, you can indicate to the server that you would like to reset the prop. This is useful when you want to clear the prop value before merging new data, such as when the user enters a new search query on a paginated list.

The `reset` request option accepts an array of the props keys you would like to reset.

:::tabs key:frameworks
== Vue

```js
import { router } from '@inertiajs/vue3'

router.reload({ reset: ['users'] })
```

== React

```js
import { router } from '@inertiajs/react'

router.reload({ reset: ['users'] })
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.reload({ reset: ['users'] })
```

:::
