# Layouts

Most applications share common UI elements across pages, such as a primary navigation bar, sidebar, or footer. Layout components let you define this shared UI once and wrap your pages with it automatically.

## Creating Layouts

A layout is a standard component that accepts child content. There is nothing Inertia-specific about it.

:::tabs key:frameworks

== Vue

```vue
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

```jsx
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

== Svelte

```svelte
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

You may use a layout by wrapping your page content with it directly. However, this approach forces the layout instance to be destroyed and recreated between visits.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import Layout from './Layout'

defineProps({ user: Object })
</script>

<template>
  <Layout>
    <h1>Welcome</h1>
    <p>Hello {{ user.name }}, welcome to your first Inertia app!</p>
  </Layout>
</template>
```

== React

```jsx
import Layout from './Layout'

export default function Welcome({ user }) {
  return (
    <Layout>
      <h1>Welcome</h1>
      <p>Hello {user.name}, welcome to your first Inertia app!</p>
    </Layout>
  )
}
```

== Svelte

```svelte
<script>
  import Layout from './Layout.svelte'

  let { user } = $props()
</script>

<Layout>
  <h1>Welcome</h1>
  <p>Hello {user.name}, welcome to your first Inertia app!</p>
</Layout>
```

:::

## Persistent Layouts

Wrapping a page with a layout as a child component works, but it means the layout is destroyed and recreated on every visit. This prevents maintaining layout state across navigations, such as an audio player that should keep playing or a sidebar that should retain its scroll position.

Persistent layouts solve this by telling Inertia which layout to use for a page. Inertia then manages the layout instance separately, keeping it alive between visits.

:::tabs key:frameworks

== Vue

```vue
<script>
import Layout from './Layout'

export default {
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

```jsx
import Layout from './Layout'

const Welcome = ({ user }) => {
  return (
    <>
      <h1>Welcome</h1>
      <p>Hello {user.name}, welcome to your first Inertia app!</p>
    </>
  )
}

Welcome.layout = Layout

export default Welcome
```

== Svelte

```svelte
<script module>
  export { default as layout } from './Layout.svelte'
</script>

<script>
  let { user } = $props()
</script>

<h1>Welcome</h1><p>Hello {user.name}, welcome to your first Inertia app!</p>
```

:::

<Vue>

Vue 3.3+ users may alternatively use [defineOptions](https://vuejs.org/api/sfc-script-setup.html#defineoptions) to define a layout within `<script setup>`:

```vue
<script setup>
import Layout from './Layout'
defineOptions({ layout: Layout })
</script>
```

</Vue>

### Nested Layouts

You may create more complex layout arrangements using nested layouts. Pass an array of layout components to wrap the page in multiple layers.

:::tabs key:frameworks

== Vue

```vue
<script>
import SiteLayout from './SiteLayout'
import NestedLayout from './NestedLayout'

export default {
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

== React

```jsx
import SiteLayout from './SiteLayout'
import NestedLayout from './NestedLayout'

const Welcome = ({ user }) => {
  return (
    <>
      <h1>Welcome</h1>
      <p>Hello {user.name}, welcome to your first Inertia app!</p>
    </>
  )
}

Welcome.layout = [SiteLayout, NestedLayout]

export default Welcome
```

== Svelte

```svelte
<script module>
  import SiteLayout from './SiteLayout.svelte'
  import NestedLayout from './NestedLayout.svelte'

  export const layout = [SiteLayout, NestedLayout]
</script>

<script>
  let { user } = $props()
</script>

<h1>Welcome</h1><p>Hello {user.name}, welcome to your first Inertia app!</p>
```

:::

## Default Layouts

@available_since core=3.0.0

The `layout` option in `createInertiaApp` lets you define a default layout for all pages, saving you from defining it on every page individually. Per-page layouts always take precedence over the default.

```js
import Layout from './Layout'

createInertiaApp({
  layout: () => Layout,
  // ...
})
```

You may also conditionally return a layout based on the page name. For example, you may wish to exclude public pages from the default layout.

```js
import Layout from './Layout'

createInertiaApp({
  layout: (name) => {
    if (name.startsWith('Public/')) {
      return null
    }

    return Layout
  },
  // ...
})
```

The full page object is also available as the second argument, giving you access to the page's URL, props, and other metadata.

The `layout` callback supports all layout formats, including arrays for [nested layouts](#nested-layouts), named objects for [named layouts](#targeting-named-layouts), and tuples for [static props](#static-props).

### Using the Resolve Callback

You may also set a default layout inside the `resolve` callback by mutating the resolved page component. The callback receives the component name and the full page object, which is useful when you need to conditionally apply layouts based on page data.

:::tabs key:frameworks

== Vue

```js
import Layout from './Layout'

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

```js
import Layout from './Layout'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.jsx', { eager: true })
    let page = pages[`../pages/${name}.jsx`]
    page.default.layout = page.default.layout || Layout
    return page
  },
  // ...
})
```

== Svelte

```js
import Layout from './Layout'

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

## Layout Props

@available_since core=3.0.0

Persistent layouts often need dynamic data from the current page, such as a page title, the active navigation item, or a sidebar toggle. Layout props provide a way to define defaults in your layout and override them from any page.

### Defining Defaults

Use the `useLayoutProps` hook in your layout component to declare which props the layout accepts and their default values.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { useLayoutProps } from '@inertiajs/vue3'

const layout = useLayoutProps({
  title: 'My App',
  showSidebar: true,
})
</script>

<template>
  <header>{{ layout.title }}</header>
  <aside v-if="layout.showSidebar">Sidebar</aside>
  <main>
    <slot />
  </main>
</template>
```

== React

```jsx
import { useLayoutProps } from '@inertiajs/react'

export default function Layout({ children }) {
  const { title, showSidebar } = useLayoutProps({
    title: 'My App',
    showSidebar: true,
  })

  return (
    <>
      <header>{title}</header>
      {showSidebar && <aside>Sidebar</aside>}
      <main>{children}</main>
    </>
  )
}
```

== Svelte

```svelte
<script>
  import { useLayoutProps } from '@inertiajs/svelte'

  const layout = useLayoutProps({
    title: 'My App',
    showSidebar: true,
  })

  let { children } = $props()
</script>

<header>{layout.title}</header>
{#if layout.showSidebar}
  <aside>Sidebar</aside>
{/if}
<main>
  {@render children()}
</main>
```

:::

The defaults object defines which keys the layout will respond to. Only keys declared in the defaults are included in the merged result. Any extra keys set from pages are ignored.

<Vue>

In Vue, `useLayoutProps` returns a `ComputedRef`, so access its properties directly (e.g., `layout.title`). The values update reactively when pages set new layout props.

</Vue>

<Svelte>

In Svelte, `useLayoutProps` returns a reactive object. Access its properties directly (e.g., `layout.title`). The values update reactively when pages set new layout props.

</Svelte>

### Setting Props From Pages

Use the `setLayoutProps` function from any page component to update the layout's props dynamically.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import { setLayoutProps } from '@inertiajs/vue3'

setLayoutProps({
  title: 'Dashboard',
  showSidebar: false,
})
</script>

<template>
  <h1>Dashboard</h1>
</template>
```

== React

```jsx
import { setLayoutProps } from '@inertiajs/react'

export default function Dashboard() {
  setLayoutProps({
    title: 'Dashboard',
    showSidebar: false,
  })

  return <h1>Dashboard</h1>
}
```

== Svelte

```svelte
<script>
  import { setLayoutProps } from '@inertiajs/svelte'

  setLayoutProps({
    title: 'Dashboard',
    showSidebar: false,
  })
</script>

<h1>Dashboard</h1>
```

:::

The layout will re-render with the merged values: `{ title: 'Dashboard', showSidebar: false }`.

### Targeting Named Layouts

You may also define your persistent layouts as a named object, allowing you to target specific layouts with props.

:::tabs key:frameworks

== Vue

```vue
<script>
import AppLayout from './AppLayout'
import ContentLayout from './ContentLayout'

export default {
  layout: {
    app: AppLayout,
    content: ContentLayout,
  },
}
</script>
```

== React

```jsx
import AppLayout from './AppLayout'
import ContentLayout from './ContentLayout'

Dashboard.layout = {
  app: AppLayout,
  content: ContentLayout,
}
```

== Svelte

```svelte
<script module>
  import AppLayout from './AppLayout.svelte'
  import ContentLayout from './ContentLayout.svelte'

  export const layout = {
    app: AppLayout,
    content: ContentLayout,
  }
</script>
```

:::

Use `setLayoutPropsFor` to set props for a specific named layout.

:::tabs key:frameworks

== Vue

```js
import { setLayoutPropsFor } from '@inertiajs/vue3'

setLayoutPropsFor('sidebar', {
  collapsed: true,
})
```

== React

```js
import { setLayoutPropsFor } from '@inertiajs/react'

setLayoutPropsFor('sidebar', {
  collapsed: true,
})
```

== Svelte

```js
import { setLayoutPropsFor } from '@inertiajs/svelte'

setLayoutPropsFor('sidebar', {
  collapsed: true,
})
```

:::

Named layout props are merged with shared layout props, with named props taking priority.

### Static Props

You may also pass static props directly in your persistent layout definition using a tuple. Static props are set once when the layout is defined and don't change between page navigations.

:::tabs key:frameworks

== Vue

```vue
<script>
import Layout from './Layout'

export default {
  layout: [Layout, { title: 'Dashboard' }],
}
</script>

<script setup>
defineProps({ user: Object })
</script>

<template>
  <h1>Dashboard</h1>
</template>
```

== React

```jsx
import Layout from './Layout'

const Dashboard = ({ user }) => {
  return <h1>Dashboard</h1>
}

Dashboard.layout = [Layout, { title: 'Dashboard' }]

export default Dashboard
```

== Svelte

```svelte
<script module>
  import Layout from './Layout.svelte'

  export const layout = [Layout, { title: 'Dashboard' }]
</script>

<script>
  let { user } = $props()
</script>

<h1>Dashboard</h1>
```

:::

Named layouts may also include static props using the same tuple syntax.

```js
Dashboard.layout = {
  app: [AppLayout, { theme: 'dark' }],
  content: [ContentLayout, { padding: 'sm' }],
}
```

For unnamed nested layouts with static props, use an array of tuples.

```js
Dashboard.layout = [
  [AppLayout, { title: 'Dashboard' }],
  [ContentLayout, { padding: 'sm' }],
]
```

### Merge Priority

Layout props are resolved from three sources with the following priority (highest to lowest):

1. **Dynamic props** - set via `setLayoutProps()` or `setLayoutPropsFor()`
2. **Static props** - defined in the persistent layout definition
3. **Defaults** - declared in `useLayoutProps()`

Only keys present in the defaults are included in the final result.

### Auto-Reset on Navigation

Dynamic layout props are automatically reset to their defaults when navigating to a new page (unless `preserveState` is enabled). This ensures each page starts with a clean slate and only the layout props explicitly set by that page are applied.

### Resetting Props

You may also manually reset all dynamic layout props back to their defaults using `resetLayoutProps`.

:::tabs key:frameworks

== Vue

```js
import { resetLayoutProps } from '@inertiajs/vue3'

resetLayoutProps()
```

== React

```js
import { resetLayoutProps } from '@inertiajs/react'

resetLayoutProps()
```

== Svelte

```js
import { resetLayoutProps } from '@inertiajs/svelte'

resetLayoutProps()
```

:::
