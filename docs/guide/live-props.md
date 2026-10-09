# Live Props

@available_since rails=master

Live props refresh themselves when the server broadcasts a change. You mark a prop as live on a stream, broadcast to that stream when data changes, and every page showing the prop reloads it over Action Cable. If you know Turbo, this is `turbo_stream_from` and `broadcasts_refreshes` for Inertia props.

> [!NOTE]
> Live props need the live props client from Inertia core ([inertiajs/inertia#3232](https://github.com/inertiajs/inertia/pull/3232)), which isn't released yet.

## Setup

Live props travel over Action Cable, so the browser needs the Action Cable client and the server needs a channel to subscribe to.

First, install the Action Cable client:

```bash
npm install @rails/actioncable
```

Then pass the Action Cable transport to `createInertiaApp`:

:::tabs key:frameworks

== Vue

```js
import { createInertiaApp } from '@inertiajs/vue3'
import { actionCable } from '@inertiajs/core/actionCable'
import { createConsumer } from '@rails/actioncable'

createInertiaApp({
  live: actionCable({ consumer: createConsumer() }),
  // ...
})
```

== React

```js
import { createInertiaApp } from '@inertiajs/react'
import { actionCable } from '@inertiajs/core/actionCable'
import { createConsumer } from '@rails/actioncable'

createInertiaApp({
  live: actionCable({ consumer: createConsumer() }),
  // ...
})
```

== Svelte

```js
import { createInertiaApp } from '@inertiajs/svelte'
import { actionCable } from '@inertiajs/core/actionCable'
import { createConsumer } from '@rails/actioncable'

createInertiaApp({
  live: actionCable({ consumer: createConsumer() }),
  // ...
})
```

:::

Finally, make sure your app has `app/channels/inertia_channel.rb`. The install generator creates it in apps that use Action Cable. In an existing app, add it yourself:

```ruby
class InertiaChannel < InertiaRails::LiveChannel
end
```

> [!TIP]
> With [server-side rendering](/guide/server-side-rendering), `createConsumer()` can't run on the server because it reads `document`. Create the consumer in the browser only:
>
> ```js
> const consumer = typeof window !== 'undefined' ? createConsumer() : undefined
> ```

## Making a Prop Live

Use `InertiaRails.live` with the stream the prop listens to. Streams follow the same rules as Turbo's `turbo_stream_from`: a record is named by its GlobalID, and several arguments form one stream.

```ruby
class ExhibitsController < ApplicationController
  def show
    @exhibit = Exhibit.find(params[:id])

    render inertia: {
      exhibit: InertiaRails.live(@exhibit) { @exhibit.as_json(only: %i[id title]) },
      guestbook: InertiaRails.live(@exhibit, :guestbook) { @exhibit.guestbook_entries.last(50) },
    }
  end
end
```

Here `exhibit` listens to the exhibit's stream, and `guestbook` listens to its own stream, `[@exhibit, :guestbook]`, so the two refresh independently.

A live prop behaves like a regular prop: it's included on full page loads and on partial reloads that ask for it.

### Other Prop Types

The `defer`, `optional`, `once`, and `always` props take a `live:` option. A deferred or optional prop subscribes right away, even before it loads.

```ruby
render inertia: {
  related: InertiaRails.defer(live: @exhibit) { @exhibit.related },
  catalog_size: InertiaRails.once(live: :exhibits) { Exhibit.count },
}
```

Live updates aren't supported on merge props, deep merge props, or scroll props. Passing `live:` to them raises an `ArgumentError`.

### Throttling

By default, the client reloads a live prop at most once a second. Use `throttle:` to change that for a prop, in milliseconds or as a duration:

```ruby
InertiaRails.live(@exhibit, :visitors, throttle: 4000) { @exhibit.visitors_count }
InertiaRails.defer(live: @exhibit, throttle: 4.seconds) { @exhibit.related }
```

Broadcasts that arrive close together are merged into one partial reload.

### Several Streams

A prop that depends on more than one record can listen to several streams with `streams:`. Each element is one stream, and an inner array forms a single stream:

```ruby
InertiaRails.live(streams: [@order, [current_user, :alerts]]) { alerts_for(@order) }
InertiaRails.defer(live: { streams: [@order, current_user] }) { summary_for(@order) }
```

## Broadcasting Changes

Call `InertiaRails.broadcast` with the same arguments the prop listens to. Every page showing the prop reloads it with a partial reload.

```ruby
class GuestbookEntriesController < ApplicationController
  def create
    @exhibit = Exhibit.find(params[:exhibit_id])
    @exhibit.guestbook_entries.create!(entry_params)

    InertiaRails.broadcast(@exhibit, :guestbook)

    redirect_to @exhibit
  end
end
```

The broadcast carries no data. Each page reloads the prop through your controller, with the current user's session, so it only sees what that user is allowed to see.

`InertiaRails.broadcast_later` does the same from a background job, so a failing cable server doesn't fail the request. It takes the same arguments, except `props:`.

### Skipping the Sender

Broadcasts reach every page, including the one whose request caused the change. Pass `to_others: true` to skip that page:

```ruby
InertiaRails.broadcast(@exhibit, :guestbook, to_others: true)
```

Use it when the sender already has fresh data, for example after a redirect. Leave it off when the sender updates through `useHttp` or a request without a redirect, or its page stays stale.

### From Models

`inertia_broadcasts` and `inertia_broadcasts_to` work like Turbo's `broadcasts_refreshes` and `broadcasts_refreshes_to`, through background jobs:

```ruby
class Exhibit < ApplicationRecord
  # Create refreshes the :exhibits stream, update and destroy refresh the exhibit's own stream
  inertia_broadcasts
end

class GuestbookEntry < ApplicationRecord
  belongs_to :exhibit, touch: true

  inertia_broadcasts_to ->(entry) { [entry.exhibit, :guestbook] }
end
```

> [!NOTE]
> As with Turbo, `inertia_broadcasts` doesn't refresh the `:exhibits` stream when a single exhibit changes. If an index page must show those updates too, add `inertia_broadcasts_to ->(_exhibit) { :exhibits }`.

To make many changes without broadcasting, wrap them in `suppressing_inertia_broadcasts`. It covers that model's broadcasts on the current thread. Broadcasts start on commit, so keep any transaction inside the block:

```ruby
Exhibit.suppressing_inertia_broadcasts do
  Exhibit.find_each { |exhibit| exhibit.update!(visitors: 0) }
end
```

### Pushing Values

A broadcast can carry new values with `props:`. Pages write them straight into the prop, with no request:

```ruby
InertiaRails.broadcast(@order, props: { status: @order.status })
```

> [!WARNING]
> Pushed values go to every page subscribed to the stream, whoever is looking at it. Only push data every subscriber may see. For anything user-specific, broadcast without `props:` and let each page reload.

Keys are prop names as the page lists them, so a nested prop takes its full path: `props: { 'stats.revenue' => 42 }`. Props a page listens to on that stream but the broadcast doesn't carry are reloaded as usual.

Pushed values go through the global [`prop_transformer`](/guide/configuration#prop-transformer) and [`preserve_big_integers`](/guide/configuration#preserve-big-integers) settings. If the transformer renames a top-level prop, the page reloads that prop instead. Settings from `inertia_config` or `render` don't apply to broadcasts, so don't push values for props a transformer from `inertia_config` renames.

## Client Side

Live props arrive as regular page props, so your components don't change. To show a loading state while a live prop reloads, use `useProp`:

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { useProp } from '@inertiajs/vue3'

const { value: guestbook, loading } = useProp('guestbook')
</script>

<template>
  <p v-if="loading">Refreshing…</p>
  <Entry v-for="entry in guestbook" :key="entry.id" :entry="entry" />
</template>
```

== React

```jsx
import { useProp } from '@inertiajs/react'

export default function Guestbook() {
  const guestbook = useProp('guestbook')

  return (
    <>
      {guestbook.loading && <p>Refreshing…</p>}
      {guestbook.value.map((entry) => (
        <Entry key={entry.id} entry={entry} />
      ))}
    </>
  )
}
```

== Svelte

```svelte
<script>
  import { useProp } from '@inertiajs/svelte'

  const guestbook = useProp('guestbook')
</script>

{#if guestbook.loading}
  <p>Refreshing…</p>
{/if}
{#each guestbook.value as entry (entry.id)}
  <Entry {entry} />
{/each}
```

:::

## Authorization

The page object carries signed stream names, and the channel only subscribes to names it signed. Rendering a page is what grants the right to listen to its streams, the same model as Turbo streams.

To check more on subscribe, override `subscribed` in your `InertiaChannel`:

```ruby
class InertiaChannel < InertiaRails::LiveChannel
  def subscribed
    current_user ? super : reject
  end
end
```

> [!WARNING]
> Signed stream names don't expire, as with Turbo. Someone who lost access can keep listening with a name from an old page. Broadcasts without `props:` only reveal that something changed. If you push values, add a check in `subscribed`.

In a multi-tenant app where records in different tenants share ids, add the tenant to the stream, for example `InertiaRails.live(current_tenant, @exhibit)`. Otherwise one tenant's broadcasts reach another tenant's pages.

## Caching

A live prop can also be [cached](/guide/cached-props). Key the cache by the record, so the key changes when the record does and the reload gets fresh data:

```ruby
InertiaRails.defer(live: @exhibit, cache: @exhibit) { ExpensiveStats.for(@exhibit) }
```

With a fixed key such as `cache: 'stats'`, a live reload returns the cached value until the cache expires.

## AnyCable

Live props work with [AnyCable](https://anycable.io) without changes. When AnyCable is configured, stream names are signed in its format with its `streams_secret`, so anycable-go can serve subscriptions on its own, without calling Rails:

```js
actionCable({
  consumer: createConsumer(),
  identifier: ({ name }) => ({ channel: '$pubsub', signed_stream_name: name }),
})
```

Checks in `InertiaChannel#subscribed` don't run in this mode.
