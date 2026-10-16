# Big Integers

@available_since rails=3.23.0 core=3.8.0

JavaScript can't represent integers above `2**53 - 1` exactly, so it rounds them while parsing JSON. An ID like `900719925474099988` from a `bigint` column or a generator like Twitter's Snowflake reaches your components as `900719925474100000`. With big integer support enabled, Inertia Rails sends those values in a form the client turns into native `BigInt` values, following the JSON convention [documented on MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt#use_within_json).

## Enabling Big Integers

Big integer support is disabled by default. It's enabled entirely on the server, so there is nothing to configure on the client. Set the `preserve_big_integers` config value to `true`, or set the `INERTIA_PRESERVE_BIG_INTEGERS` environment variable.

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.preserve_big_integers = true
end
```

You can also enable it for all actions in a controller:

```ruby
class OrdersController < ApplicationController
  inertia_config(preserve_big_integers: true)
end
```

Or for a single response, which is handy when only a few pages deal with large integers. Passing `false` opts a single response out once the feature is enabled in your configuration.

```ruby
render inertia: { order: order }, preserve_big_integers: true
render inertia: { report: report }, preserve_big_integers: false
```

## How Values Are Transported

Integers outside JavaScript's safe range are wrapped in a marker object, and the page is flagged with `preserveBigIntegers: true`. The client turns each marker back into a `BigInt`, so your component receives the exact value.

```ruby
render inertia: { id: 900719925474099988 }
# The response carries "id": {"$bigint": "900719925474099988"}
```

:::tabs key:frameworks

== Vue

```vue
<script setup>
defineProps({ id: BigInt })
</script>

<template>
  <p>User {{ id }}</p>
  <!-- User 900719925474099988 -->
</template>
```

== React

```jsx
export default function Show({ id }) {
  return <p>User {String(id)}</p>
  // User 900719925474099988
}
```

== Svelte

```svelte
<script>
  let { id } = $props()
</script>

<p>User {id}</p>
<!-- User 900719925474099988 -->
```

:::

Integers within the safe range stay regular numbers, so the same prop may arrive as a number or a `BigInt` depending on its value. [Flash data](/guide/flash-data) gets the same treatment as props.

Inertia Rails looks for big integers in the finished page, after [`prop_transformer`](/guide/configuration#prop-transformer) runs. It finds them inside Active Record models, objects with `as_json` or `to_inertia`, [cached props](/guide/cached-props), JSON fragments, and [infinite scroll](/guide/infinite-scroll) page numbers. Partial reloads, deferred props, and the page sent to the [SSR server](/guide/server-side-rendering) are covered too. In your root template, [`inertia_page`](/guide/responses#inertia-page) holds the markers instead of the integers.

The client only revives markers on pages with the flag, so an app that already sends its own `{"$bigint": "..."}` objects keeps receiving them as plain objects everywhere else.

> [!WARNING]
> On pages with the flag, the client turns every `{"$bigint": "..."}` object into a `BigInt`, including ones that come from user data. A marker that holds anything but digits makes the page fail to load.

## Submitting Big Integers

A `BigInt` submitted through the router, a form, or [Precognition](/guide/precognition) is sent as its digits, the same way form data and query strings send numbers. Your controller receives a numeric string, which Active Record casts as usual.

```js
router.post('/orders', { id: props.order.id })
```

```ruby
def create
  order = Order.find(params.require(:id))
  # ...
end
```

The [`useHttp`](/guide/http-requests) hook doesn't handle `BigInt` values, since it's often used to call third-party APIs. Convert them to strings before sending.

## Testing

The Inertia Rails [testing helpers](/guide/testing) turn markers back into integers, so you can assert against the values you passed to the response.

:::tabs key:tests

== RSpec

```ruby
expect(inertia).to have_props(order: { id: 900719925474099988 })
expect(inertia.props[:order][:id]).to eq 900719925474099988
```

== Minitest

```ruby
assert_inertia_props order: { id: 900719925474099988 }
assert_equal 900719925474099988, inertia.props[:order][:id]
```

:::
