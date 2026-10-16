# Polling

## Poll Helper

Polling your server for new information on the current page is common, so Inertia provides a poll helper designed to help reduce the amount of boilerplate code. In addition, the poll helper will automatically stop polling when the page is unmounted.

The only required argument is the polling interval in milliseconds.

:::tabs key:frameworks

== Vue

```js
import { usePoll } from '@inertiajs/vue3'

usePoll(2000)
```

== React

```jsx
import { usePoll } from '@inertiajs/react'

usePoll(2000)
```

== Svelte

```js
import { usePoll } from '@inertiajs/svelte'

usePoll(2000)
```

:::

If you need to pass additional request options to the poll helper, you can pass any of the `router.reload` options as the second parameter.

:::tabs key:frameworks

== Vue

```js
import { usePoll } from '@inertiajs/vue3'

usePoll(2000, {
  onStart() {
    console.log('Polling request started')
  },
  onFinish() {
    console.log('Polling request finished')
  },
})
```

== React

```jsx
import { usePoll } from '@inertiajs/react'

usePoll(2000, {
  onStart() {
    console.log('Polling request started')
  },
  onFinish() {
    console.log('Polling request finished')
  },
})
```

== Svelte

```js
import { usePoll } from '@inertiajs/svelte'

usePoll(2000, {
  onStart() {
    console.log('Polling request started')
  },
  onFinish() {
    console.log('Polling request finished')
  },
})
```

:::

You may also pass a function that returns the request options. The function is evaluated on every tick, allowing the poll to reflect the latest component state.

@available_since core=3.2.0

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { usePoll } from '@inertiajs/vue3'
const props = defineProps({ counter: Number })
usePoll(2000, () => ({
  data: { counter_seen: props.counter },
  only: ['last_received'],
}))
</script>
```

== React

```jsx
import { usePoll } from '@inertiajs/react'

export default ({ counter }) => {
  usePoll(2000, () => ({
    data: { counter_seen: counter },
    only: ['last_received'],
  }))
}
```

== Svelte

```js
import { usePoll } from '@inertiajs/svelte'

let { counter } = $props()

usePoll(2000, () => ({
  data: { counter_seen: counter },
  only: ['last_received'],
}))
```

:::

If you'd like more control over the polling behavior, the poll helper provides `stop` and `start` methods that allow you to manually start and stop polling. You can pass the `autoStart: false` option to the poll helper to prevent it from automatically starting polling when the component is mounted.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { usePoll } from '@inertiajs/vue3'

const { start, stop } = usePoll(
  2000,
  {},
  {
    autoStart: false,
  },
)
</script>

<template>
  <button @click="start">Start polling</button>
  <button @click="stop">Stop polling</button>
</template>
```

== React

```jsx
import { usePoll } from '@inertiajs/react'

export default () => {
  const { start, stop } = usePoll(
    2000,
    {},
    {
      autoStart: false,
    },
  )

  return (
    <div>
      <button onClick={start}>Start polling</button>
      <button onClick={stop}>Stop polling</button>
    </div>
  )
}
```

== Svelte

```svelte
<script>
  import { usePoll } from '@inertiajs/svelte'

  const { start, stop } = usePoll(
    2000,
    {},
    {
      autoStart: false,
    },
  )
</script>

<button onclick={start}>Start polling</button>
<button onclick={stop}>Stop polling</button>
```

:::

@available_since core=3.7.0

The poll helper also returns a reactive `polling` value that reflects whether the poll is running, making it ideal for rendering a pause or resume button. The value doesn't indicate whether a request is in flight.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { usePoll } from '@inertiajs/vue3'

const { start, stop, polling } = usePoll(2000)
</script>

<template>
  <button v-if="polling" @click="stop">Pause updates</button>
  <button v-else @click="start">Resume updates</button>
</template>
```

== React

```jsx
import { usePoll } from '@inertiajs/react'

export default () => {
  const { start, stop, polling } = usePoll(2000)

  return polling ? (
    <button onClick={stop}>Pause updates</button>
  ) : (
    <button onClick={start}>Resume updates</button>
  )
}
```

== Svelte

```svelte
<script>
  import { usePoll } from '@inertiajs/svelte'

  const poll = usePoll(2000)
</script>

{#if poll.polling}
  <button onclick={poll.stop}>Pause updates</button>
{:else}
  <button onclick={poll.start}>Resume updates</button>
{/if}
```

:::

## Concurrency Mode

@available_since core=3.2.0

By default, the poll helper fires a new request on every tick, even when the previous request is still in flight. You may control this behavior with the `mode` option, which accepts one of three values: `overlap`, `cancel`, or `rest`.

The default `overlap` mode allows requests to run in parallel. The `cancel` mode aborts any in-flight request when the next tick fires. The `rest` mode treats the interval as the time between the end of the previous request and the start of the next one, so requests never overlap.

:::tabs key:frameworks

== Vue

```js
import { usePoll } from '@inertiajs/vue3'

usePoll(
  2000,
  {},
  {
    mode: 'rest',
  },
)
```

== React

```jsx
import { usePoll } from '@inertiajs/react'

usePoll(
  2000,
  {},
  {
    mode: 'rest',
  },
)
```

== Svelte

```js
import { usePoll } from '@inertiajs/svelte'

usePoll(
  2000,
  {},
  {
    mode: 'rest',
  },
)
```

:::

## Background Tabs

@available_since core=3.9.0

By default, the poll helper throttles requests by 90% when the browser tab is in the background. You may control this behavior with the `background` option, which accepts one of three values: `throttle`, `pause`, or `continue`.

The `pause` mode stops polling entirely while the tab is hidden. Once the tab becomes visible again, polling resumes, firing a request immediately if the interval has already elapsed since the last one. The `continue` mode keeps polling at the regular interval, even while the tab is hidden.

:::tabs key:frameworks

== Vue

```js
import { usePoll } from '@inertiajs/vue3'

usePoll(
  2000,
  {},
  {
    background: 'pause',
  },
)
```

== React

```jsx
import { usePoll } from '@inertiajs/react'

usePoll(
  2000,
  {},
  {
    background: 'pause',
  },
)
```

== Svelte

```js
import { usePoll } from '@inertiajs/svelte'

usePoll(
  2000,
  {},
  {
    background: 'pause',
  },
)
```

:::

> [!NOTE]
> The `keepAlive` option is deprecated in favor of `background: 'continue'`.
