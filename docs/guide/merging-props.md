# Merging props

Inertia overwrites props with the same name when reloading a page. However, you may need to merge new data with existing data instead. For example, when implementing a "load more" button for paginated results. The [Infinite scroll](/guide/infinite-scroll) component uses prop merging under the hood.

Prop merging only works during [partial reloads](/guide/partial-reloads). Full page visits will always replace props entirely, even if you've marked them for merging.

## Merge methods

@available_since rails=3.8.0 core=2.0.8

To merge a prop instead of overwriting it, you may use the `InertiaRails.merge` method when returning your response.

```ruby
class UsersController < ApplicationController
  include Pagy::Method

  def index
    _pagy, records = pagy(:offset, User.all)

    render inertia: {
      users: InertiaRails.merge { records.as_json(...) },
    }
  end
end
```

The `InertiaRails.merge` method will append new items to existing arrays at the root level.

```ruby
# Append at root level (default)...
InertiaRails.merge { items }
```

@available_since rails=3.12.0 core=2.2.0

You may change this behavior to prepend items instead.

```ruby
# Prepend at root level...
InertiaRails.merge(prepend: true) { items }
```

For more precise control, you can target specific nested properties for merging while replacing the rest of the object.

```ruby
# Only append to the 'data' array, replace everything else...
InertiaRails.merge(append: 'data') { {data: data, meta: meta} }

# Prepend to the 'messages' array...
InertiaRails.merge(prepend: 'messages') { chat_data }
```

You can combine multiple operations and target several properties at once.

```ruby
InertiaRails.merge(
  append: 'posts',
  prepend: 'announcements'
) { forum_data }

# Target multiple properties...
InertiaRails.merge(
  append: ['notifications', 'activities']
) { dashboard_data }
```

On the client side, Inertia handles all the merging automatically according to your server-side configuration.

## Matching items

@available_since rails=3.8.0 core=2.0.8

When merging arrays, you may use the `match_on` parameter to match existing items by a specific field and update them instead of appending new ones.

```ruby
# Match posts by ID, update existing ones...
InertiaRails.merge(match_on: 'id') { post_data }
```

@available_since rails=3.12.0 core=2.2.0

You may also use append and prepend with a hash to specify the field to match.

```ruby
# Match posts by ID, update existing ones...
InertiaRails.merge(append: 'data', match_on: 'data.id') { post_data }

# Same as above, but using a hash shortcut...
InertiaRails.merge(append: { data: 'id' }) { post_data }

# Multiple properties with different match fields...
InertiaRails.merge(append: {
  'users.data' => 'id',
  'messages' => 'uuid',
}) { complex_data }
```

In the first two examples, Inertia will iterate over the data array and attempt to match each item by its id field. If a match is found, the existing item will be replaced. If no match is found, the new item will be appended.

## Deep merge

@available_since rails=3.8.0 core=2.0.8

Instead of specifying which nested paths should be merged, you may use `InertiaRails.deep_merge` to ensure a deep merge of the entire structure.

```ruby
class ChatController < ApplicationController
  def index
    chat_data = [
      messages: [
        [id: 4, text: 'Hello there!', user: 'Alice'],
        [id: 5, text: 'How are you?', user: 'Bob'],
      ],
      online: 12,
    ]

    render inertia: {
      chat: InertiaRails.deep_merge(chat_data, match_on: 'messages.id')
    }
  end
end
```

> [!NOTE] > `InertiaRails.deep_merge` was introduced before `InertiaRails.merge` had support for prepending and targeting nested paths. In most cases, `InertiaRails.merge` with its append and prepend parameters should be sufficient.

## Client side visits

You can also merge props directly on the client side without making a server request using [client side visits](/guide/manual-visits#client-side-visits). Inertia provides [prop helper methods](/guide/manual-visits#prop-helpers) that allow you to append, prepend, or replace prop values.

## Combining with deferred props

You can also combine [deferred props](/guide/deferred-props) with mergeable props to defer the loading of the prop and ultimately mark it as mergeable once it's loaded.

```ruby
class UsersController < ApplicationController
  include Pagy::Method

  def index
    pagy, records = pagy(:offset, User.all)

    render inertia: {
      results: InertiaRails.defer(deep_merge: true) { records.as_json(...) },
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
