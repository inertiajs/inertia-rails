# Merging props

By default, Inertia overwrites props with the same name when reloading a page. However, there are instances, such as pagination or infinite scrolling, where that is not the desired behavior. In these cases, you can merge props instead of overwriting them.

## Server side

To specify that a prop should be merged, you can use the `merge` method on the prop value.

```ruby
class UsersController < ApplicationController
  include Pagy::Backend

  def index
    _pagy, records = pagy(User.all)

    render inertia: 'Users/Index', props: {
      results: InertiaRails.merge { records },
    }
  end
end
```

On the client side, Inertia detects that this prop should be merged. If the prop returns an array, it will append the response to the current prop value. If it's an object, it will merge the response with the current prop value.

You can also combine [deferred props](/guide/deferred-props) with mergeable props to defer the loading of the prop and ultimately mark it as mergeable once it's loaded.

```ruby
class UsersController < ApplicationController
  include Pagy::Backend

  def index
    render inertia: 'Users/Index', props: {
      results: InertiaRails.defer(merge: true) { pagy(User.all)[1] },
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

router.reload({ reset: ['results'] })
```

== React

```js
import { router } from '@inertiajs/react'

router.reload({ reset: ['results'] })
```

== Svelte 4|Svelte 5

```js
import { router } from '@inertiajs/svelte'

router.reload({ reset: ['results'] })
```

:::
