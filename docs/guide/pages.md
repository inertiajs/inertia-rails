# Pages

When building applications using Inertia, each page in your application typically has its own controller / route and a corresponding JavaScript component. This allows you to retrieve just the data necessary for that page - no API required.

In addition, all of the data needed for the page can be retrieved before the page is ever rendered by the browser, eliminating the need for displaying "loading" states when users visit your application.

## Creating Pages

Inertia pages are simply JavaScript components. If you have ever written a Vue, React, or Svelte component, you will feel right at home. As you can see in the example below, pages receive data from your application's controllers as props.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import Layout from '../Layout'
import { Head } from '@inertiajs/vue3'

defineProps({ user: Object })
</script>

<template>
  <Layout>
    <Head title="Welcome" />
    <h1>Welcome</h1>
    <p>Hello {{ user.name }}, welcome to your first Inertia app!</p>
  </Layout>
</template>
```

== React

```jsx
import Layout from '../Layout'
import { Head } from '@inertiajs/react'

export default function Welcome({ user }) {
  return (
    <Layout>
      <Head title="Welcome" />
      <h1>Welcome</h1>
      <p>Hello {user.name}, welcome to your first Inertia app!</p>
    </Layout>
  )
}
```

== Svelte

```svelte
<script>
  import Layout from '../Layout.svelte'

  let { user } = $props()
</script>

<svelte:head>
  <title>Welcome</title>
</svelte:head>

<Layout>
  <h1>Welcome</h1>
  <p>Hello {user.name}, welcome to your first Inertia app!</p>
</Layout>
```

:::

Given the page above, you can render the page by returning an [Inertia
response](/guide/responses) from a controller or route. In this
example, let's assume this page is stored at
<Vue>`app/frontend/pages/users/show.vue`</Vue>
<React>`app/frontend/pages/users/show.jsx`</React>
<Svelte>`app/frontend/pages/users/show.svelte`</Svelte> within a Rails application.

```ruby
class UsersController < ApplicationController
  def show
    user = User.find(params[:id])

    render inertia: { user: }
  end
end
```

If you attempt to render a page that does not exist, the response will typically be a blank screen.

## Layouts

Most applications share common UI elements across pages. Inertia provides persistent layouts that survive page navigations, along with layout props for passing dynamic data between pages and their layouts. Visit the [layouts documentation](/guide/layouts) to learn more.
