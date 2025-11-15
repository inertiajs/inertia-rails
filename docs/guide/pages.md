# Pages

When building applications using Inertia, each page in your application typically has its own controller / route and a corresponding JavaScript component. This allows you to retrieve just the data necessary for that page - no API required.

In addition, all of the data needed for the page can be retrieved before the page is ever rendered by the browser, eliminating the need for displaying "loading" states when users visit your application.

## Creating pages

Inertia pages are simply JavaScript components. If you have ever written a Vue, React, or Svelte component, you will feel right at home. As you can see in the example below, pages receive data from your application's controllers as props.

:::tabs key:frameworks
== Vue

```vue twoslash
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

```jsx twoslash
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

== Svelte 4

```svelte twoslash
<script>
  import Layout from '../Layout'

  export let user
</script>

<svelte:head>
  <title>Welcome</title>
</svelte:head>

<Layout>
  <h1>Welcome</h1>
  <p>Hello {user.name}, welcome to your first Inertia app!</p>
</Layout>
```

== Svelte 5

```svelte twoslash
<script>
  import Layout from './Layout.svelte'

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

Given the page above, you can render the page by returning an Inertia response from a controller or route. In this example, let's assume this page is stored at `app/frontend/pages/User/Show.(jsx|vue|svelte)` within a Rails application.

```ruby
class UsersController < ApplicationController
  def show
    user = User.find(params[:id])

    render inertia: 'User/Show', props: { user: }
  end
end
```

See [the responses documentation](/guide/responses) for more information on how to return Inertia responses from your controllers.

## Creating layouts

While not required, for most projects it makes sense to create a layout component that all of your pages can use. You may have noticed in our page example above that we're wrapping the page content within a `<Layout>` component. Here's an example of such a component:

:::tabs key:frameworks
== Vue

```vue twoslash
<script setup>
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <main>
    <header>
      <Link href="/">Home</Link>
      <Link href="/about">About</Link>
      <Link href="/contact">Contact</Link>
    </header>
    <article>
      <slot />
    </article>
  </main>
</template>
```

== React

```jsx twoslash
import { Link } from '@inertiajs/react'

export default function Layout({ children }) {
  return (
    <main>
      <header>
        <Link href="/">Home</Link>
        <Link href="/about">About</Link>
        <Link href="/contact">Contact</Link>
      </header>
      <article>{children}</article>
    </main>
  )
}
```

== Svelte 4

```svelte twoslash
<script>
  import { inertia } from '@inertiajs/svelte'
</script>

<main>
  <header>
    <a use:inertia href="/">Home</a>
    <a use:inertia href="/about">About</a>
    <a use:inertia href="/contact">Contact</a>
  </header>
  <article>
    <slot />
  </article>
</main>
```

== Svelte 5

```svelte twoslash
<script>
  import { inertia } from '@inertiajs/svelte'

  let { children } = $props()
</script>

<main>
  <header>
    <a use:inertia href="/">Home</a>
    <a use:inertia href="/about">About</a>
    <a use:inertia href="/contact">Contact</a>
  </header>
  <article>
    {@render children()}
  </article>
</main>
```

:::

As you can see, there is nothing Inertia specific within this template. This is just a typical component.

## Persistent layouts

While it's simple to implement layouts as children of page components, it forces the layout instance to be destroyed and recreated between visits. This means you cannot have persistent layout state when navigating between pages.

For example, maybe you have an audio player on a podcast website that you want to continue playing as users navigate the site. Or, maybe you simply want to maintain the scroll position in your sidebar navigation between page visits. In these situations, the solution is to leverage Inertia's persistent layouts.

:::tabs key:frameworks
== Vue

```vue twoslash
<script>
import Layout from '../Layout'

export default {
  // Using a render function...
  layout: (h, page) => h(Layout, [page]),

  // Using shorthand syntax...
  layout: Layout,
}
</script>

<script setup>
defineProps({ user: Object })
</script>

<template>
  <h1>Welcome</h1>
  <p>Hello {{ user.name }}, welcome to your first Inertia app!</p>
</template>
```

== React

```jsx twoslash
import Layout from '../Layout'

const Home = ({ user }) => {
  return (
    <>
      <h1>Welcome</h1>
      <p>Hello {user.name}, welcome to your first Inertia app!</p>
    </>
  )
}

Home.layout = (page) => <Layout children={page} title="Welcome" />

export default Home
```

== Svelte 4

```svelte twoslash
<script context="module">
  export { default as layout } from './Layout.svelte'
</script>

<script>
  export let user
</script>

<h1>Welcome</h1>

<p>Hello {user.name}, welcome to your first Inertia app!</p>
```

== Svelte 5

```svelte twoslash
<script module>
  export { default as layout } from './Layout.svelte'
</script>

<script>
  let { user } = $props()
</script>

<h1>Welcome</h1>

<p>Hello {user.name}, welcome to your first Inertia app!</p>
```

:::

You can also create more complex layout arrangements using nested layouts.

:::tabs key:frameworks
== Vue

```vue twoslash
<script>
import SiteLayout from './SiteLayout'
import NestedLayout from './NestedLayout'

export default {
  // Using a render function...
  layout: (h, page) => {
    return h(SiteLayout, () => h(NestedLayout, () => page))
  },

  // Using the shorthand...
  layout: [SiteLayout, NestedLayout],
}
</script>

<script setup>
defineProps({ user: Object })
</script>

<template>
  <h1>Welcome</h1>
  <p>Hello {{ user.name }}, welcome to your first Inertia app!</p>
</template>
```

If you're using Vue 3.3+, you can alternatively use [`defineOptions`](https://vuejs.org/api/sfc-script-setup.html#defineoptions) to define a layout within `<script setup>`.
Older versions of Vue can use the [defineOptions plugin](https://vue-macros.sxzz.moe/macros/define-options.html).

```vue twoslash
<script setup>
import Layout from '../Layout'

defineOptions({ layout: Layout })
</script>
```

== React

```jsx twoslash
import SiteLayout from './SiteLayout'
import NestedLayout from './NestedLayout'

const Home = ({ user }) => {
  return (
    <>
      <h1>Welcome</h1>
      <p>Hello {user.name}, welcome to your first Inertia app!</p>
    </>
  )
}

Home.layout = (page) => (
  <SiteLayout title="Welcome">
    <NestedLayout children={page} />
  </SiteLayout>
)

export default Home
```

== Svelte 4

```svelte twoslash
<script context="module">
  import SiteLayout from './SiteLayout.svelte'
  import NestedLayout from './NestedLayout.svelte'

  // Using a render function...
  export const layout = (h, page) => {
    return h(SiteLayout, [h(NestedLayout, [page])])
  }

  // Using the shorthand...
  export const layout = [SiteLayout, NestedLayout]
</script>

<script>
  export let user
</script>

<h1>Welcome</h1>

<p>Hello {user.name}, welcome to your first Inertia app!</p>
```

== Svelte 5

```svelte twoslash
<script module>
  import SiteLayout from './SiteLayout.svelte'
  import NestedLayout from './NestedLayout.svelte'
  // Using a render function...
  export const layout = (h, page) => {
    return h(SiteLayout, [h(NestedLayout, [page])])
  }
  // Using the shorthand...
  export const layout = [SiteLayout, NestedLayout]
</script>

<script>
  let { user } = $props()
</script>

<h1>Welcome</h1>

<p>Hello {user.name}, welcome to your first Inertia app!</p>
```

:::

## Default layouts

If you're using persistent layouts, you may find it convenient to define the default page layout in the `resolve()` callback of your application's main JavaScript file.

:::tabs key:frameworks
== Vue

```js twoslash
// frontend/entrypoints/inertia.js
import Layout from '../Layout'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.vue', { eager: true })
    let page = pages[`../pages/${name}.vue`]
    page.default.layout = page.default.layout || Layout
    return page
  },
  // ...
})
```

== React

```js twoslash
// frontend/entrypoints/inertia.js
import Layout from '../Layout'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.jsx', { eager: true })
    let page = pages[`../pages/${name}.jsx`]
    page.default.layout =
      page.default.layout || ((page) => <Layout children={page} />)
    return page
  },
  // ...
})
```

== Svelte 4|Svelte 5

```js twoslash
// frontend/entrypoints/inertia.js
import Layout from '../Layout'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.svelte', { eager: true })
    let page = pages[`../pages/${name}.svelte`]
    return { default: page.default, layout: page.layout || Layout }
  },
  // ...
})
```

:::

This will automatically set the page layout to `Layout` if a layout has not already been set for that page.

You can even go a step further and conditionally set the default page layout based on the page `name`, which is available to the `resolve()` callback. For example, maybe you don't want the default layout to be applied to your public pages.

:::tabs key:frameworks
== Vue

```js twoslash
// frontend/entrypoints/inertia.js
import Layout from '../Layout'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.vue', { eager: true })
    let page = pages[`../pages/${name}.vue`]
    page.default.layout = name.startsWith('Public/') ? undefined : Layout
    return page
  },
  // ...
})
```

== React

```js twoslash
// frontend/entrypoints/inertia.js
import Layout from '../Layout'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.jsx', { eager: true })
    let page = pages[`../pages/${name}.jsx`]
    page.default.layout = name.startsWith('Public/')
      ? undefined
      : (page) => <Layout children={page} />
    return page
  },
  // ...
})
```

== Svelte 4|Svelte 5

```js twoslash
// frontend/entrypoints/inertia.js
import Layout from '../Layout'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.svelte', { eager: true })
    let page = pages[`../pages/${name}.svelte`]
    return {
      default: page.default,
      layout: name.startsWith('Public/') ? undefined : Layout,
    }
  },
  // ...
})
```

:::
