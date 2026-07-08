# Live Props

@available_since rails=master

Live props keep page props in sync across browsers in real time. A model commit broadcasts a small signal over Action Cable; every subscribed page responds with one coalesced [partial reload](/guide/partial-reloads) through your controller. The data always travels over HTTP, through your authorization and serialization — the socket only ever says _"something changed"_.

That design has a name: signals are **facts, never values**. A broadcast carries `{type, model, id}` — no attributes, no rendered payloads. Whatever a user is allowed to see is decided by the controller at reload time, exactly like any other request. A signal delivered to the wrong subscriber can only cause a wasted reload, not a data leak.

## Server side

Mark a prop as live by giving it a stream name:

```ruby
class TasksController < ApplicationController
  def index
    render inertia: {
      tasks: InertiaRails.live(:tasks) { Task.order(:created_at) },
      task_count: InertiaRails.live(:tasks) { Task.count },
    }
  end
end
```

The first argument is a _streamable_ — a symbol, string, record, or array of them (`[:project, current_user]`), resolved to a stream name the same way `turbo-rails` does it. Props sharing a streamable share one signed stream: a signal on it reloads all of them together, in a single request.

Stream names are signed with a key derived from your `secret_key_base` (override with `InertiaRails.signed_stream_verifier_key=`), so clients can subscribe only to streams the server put on their page.

Live props compose with the rest of the prop toolkit — `merge:`, `match_on:`, and `once:` work as usual:

```ruby
tasks: InertiaRails.live(:tasks, merge: true, match_on: 'id') { Task.order(:created_at) }
```

### Broadcasting from models

Mirroring Turbo's model API, include `InertiaRails::Broadcastable` and declare what a commit should broadcast:

```ruby
class Task < ApplicationRecord
  include InertiaRails::Broadcastable

  broadcasts_to ->(task) { :tasks }
end
```

`broadcasts_to` sends a typed lifecycle fact (`create`, `update`, or `destroy`) after every commit. Alternatively, `broadcasts_refreshes_to` sends a bare _reload_ signal and debounces rapid changes into one broadcast:

```ruby
class Column < ApplicationRecord
  include InertiaRails::Broadcastable

  broadcasts_refreshes_to :board, debounce: 0.5
end
```

Both macros accept `on:` (limit to `:create` / `:update` / `:destroy`) and standard `if:` / `unless:` conditions. Typed facts are deliberately never debounced — coalescing them could drop a destroy.

::: warning Hybrid apps
`turbo-rails` adds its own `broadcasts_to` to every model. When Turbo is present, the short names stay Turbo's — use the canonical prefixed macros instead, side by side:

```ruby
broadcasts_to ->(t) { t.board }          # Turbo → ERB pages
inertia_broadcasts_to ->(t) { t.board }  # Inertia → live props
```

:::

To broadcast outside a model callback:

```ruby
InertiaRails.broadcast_refresh_to(:tasks)
InertiaRails.broadcast_change_to(:tasks, record: task, action: :update)
```

And to silence a model's broadcasts during bulk operations:

```ruby
Task.suppressing_inertia_broadcasts do
  import_legacy_tasks!
end
```

### Instant destroys

Destroys normally reload through the controller like everything else. For props that are flat, id-keyed arrays of exactly one model, you can opt into client-side filtering — the row disappears instantly, without waiting for a round-trip:

```ruby
tasks: InertiaRails.live(:tasks, on_destroy: Task) { Task.order(:created_at) }
```

`on_destroy:` takes the model class (or name string) whose destroy signals may be applied locally. Keep the default (`:reload`) for windowed, ordered, nested, or multi-model props — a local removal can't know what should take the deleted row's place.

## Client side

Install the adapter for your framework (the core engine comes with it):

```shell
npm install @inertia-rails/react @rails/actioncable
```

Enable live props once, next to `createInertiaApp`:

:::tabs key:frameworks
== React

```js
// frontend/entrypoints/inertia.js
import { enableLiveProps } from '@inertia-rails/react'
import { ActionCableTransport } from '@inertia-rails/core'
import { createConsumer } from '@rails/actioncable'

enableLiveProps({
  transport: new ActionCableTransport(createConsumer()),
})
```

== Vue

```js
// frontend/entrypoints/inertia.js
import { enableLiveProps } from '@inertia-rails/vue'
import { ActionCableTransport } from '@inertia-rails/core'
import { createConsumer } from '@rails/actioncable'

enableLiveProps({
  transport: new ActionCableTransport(createConsumer()),
})
```

== Svelte

```js
// frontend/entrypoints/inertia.js
import { enableLiveProps } from '@inertia-rails/svelte'
import { ActionCableTransport } from '@inertia-rails/core'
import { createConsumer } from '@rails/actioncable'

enableLiveProps({
  transport: new ActionCableTransport(createConsumer()),
})
```

:::

That's the whole integration. Components don't subscribe to anything — the engine reads stream metadata from each page response, manages Action Cable subscriptions as you navigate, and applies updates through partial reloads. Out of the box it:

- **coalesces** bursts of signals into one reload per stream (100ms debounce plus up to 300ms of jitter, so a fleet of tabs doesn't stampede your controller — tune with `debounceMs:` / `jitterMs:`),
- **skips your own echoes** — every request carries a generated `X-Inertia-Live-Request-Id`; broadcasts triggered by this tab's own writes are recognized and ignored, since the response already contains the fresh data,
- **catches up on gaps** — after the socket (re)connects, one reload covers whatever was missed while disconnected,
- **pauses in hidden tabs** and reloads once on return, mirroring how Inertia's polling behaves.

### Pausing and connection status

:::tabs key:frameworks
== React

```jsx
import { useLiveControl, useConnectionStatus } from '@inertia-rails/react'

useLiveControl({ paused: isEditing })
const status = useConnectionStatus() // "connecting" | "connected" | "disconnected"
```

== Vue

```js
import { useLiveControl, useConnectionStatus } from '@inertia-rails/vue'

useLiveControl({ paused: isEditing }) // accepts refs/getters
const status = useConnectionStatus()
```

== Svelte

```js
import { liveControl, connectionStatus } from '@inertia-rails/svelte'

liveControl({ paused: isEditing })
const status = connectionStatus()
```

:::

A user pause and the automatic hidden-tab pause are independent — clearing one never overrides the other.

## User channels

For events that aren't prop changes — presence, typing indicators, toasts — subscribe to your own Action Cable channels through the same connection:

:::tabs key:frameworks
== React

```jsx
import { useChannel } from '@inertia-rails/react'

const { perform } = useChannel(
  'TypingChannel',
  { room_id: room.id },
  {
    typing(data) {
      setTypingUsers(data.names)
    },
    _fallback(data) {}, // messages with no matching handler
    _reconnect() {}, // the socket dropped and came back — refetch if needed
  },
)

perform('typing', { name: user.name })
```

== Vue

```js
import { useChannel } from '@inertia-rails/vue'

// params may be a ref/getter; changing them resubscribes
const { perform } = useChannel('TypingChannel', () => ({ room_id: room.id }), {
  typing(data) {
    typingUsers.value = data.names
  },
})
```

== Svelte

```js
import { channel } from '@inertia-rails/svelte'

const { perform } = channel(
  'TypingChannel',
  { room_id: room.id },
  {
    typing(data) {
      typingUsers = data.names
    },
  },
)
```

:::

Messages route to the handler named by their `action` field. Equivalent channel-plus-params subscriptions share one wire subscription regardless of how many components mount them, and passing `null` params disables the subscription (conditional, SWR-style).

## Client-side mutations

When you already know what changed — usually from a `useChannel` event carrying data — you can mutate an array prop directly instead of reloading:

:::tabs key:frameworks
== React

```jsx
import { useChannel, useLiveProp } from '@inertia-rails/react'

const messages = useLiveProp('messages') // matchOn: 'id' by default

useChannel(
  'ChatChannel',
  { room_id: room.id },
  {
    created: ({ message }) => messages.append(message),
    updated: ({ message }) => messages.update(message),
    deleted: ({ id }) => messages.remove(id),
  },
)
```

== Vue

```js
import { useChannel, useLiveProp } from '@inertia-rails/vue'

const messages = useLiveProp('messages')
```

== Svelte

```js
import { channel, liveProp } from '@inertia-rails/svelte'

const messages = liveProp('messages')
```

:::

The handle offers `append`, `prepend`, `update`, `remove`, and `set` (a full custom reducer for sorted inserts, windowing, grouping). `append`/`prepend` are upserts — an existing key is replaced in place. Mutations batch into one history-state write per tick, and removals are guarded against resurrection by reload responses that were already in flight.

::: warning You own the payload
Anything you `append` came over the socket, not through your controller. Broadcast values only on channels whose subscribers are all allowed to see them — when in doubt, broadcast a fact and reload instead. That's the entire reason live props default to reloading.
:::

## TypeScript

Augment one interface and every hook infers — prop names autocomplete, item shapes check, channel params, events, and actions type end to end:

```ts
// frontend/types/globals.d.ts
declare module '@inertia-rails/core' {
  interface TypeRegistry {
    liveProps: { tasks: Task }
    channels: {
      ChatChannel: {
        params: { room_id: number }
        receives: { created: { message: Message }; deleted: { id: number } }
        performs: { typing: { name: string } }
      }
    }
  }
}
```

Unregistered apps degrade gracefully (plain strings, `Record` payloads), and explicit generics always win: `useLiveProp<Message>('messages')`.

## Where live props don't fit

- **Sub-100ms collaboration** — cursors, canvases, text CRDTs want their own channel and client state, not HTTP reloads. Use `useChannel` and skip live props for that data.
- **Very hot streams** — a prop reloading many times per second is a polling loop with extra steps. Debounce on the model (`broadcasts_refreshes_to ... debounce:`), or reconsider the boundary.
- **Broadcast fan-out is amplification** — one commit on a stream with N subscribed tabs produces up to N reloads. The client-side jitter spreads them out, but a hot stream shared by thousands of viewers deserves a look at caching the reloaded action or rate limiting like any other endpoint.

## Testing

Broadcast debouncing is thread-based; in your test suite swap it for the inline variant:

```ruby
# rails_helper.rb
InertiaRails::ThreadDebouncer.debouncer_class = InertiaRails::ImmediateDebouncer
```

Model broadcasts then fire synchronously inside `after_commit`, so you can assert on `ActionCable.server` broadcasts (or mock `InertiaRails.broadcast_change_to`) without waiting.
