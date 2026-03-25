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

Persistent layouts often need dynamic data from the current page, such as a page title, the active navigation item, or a sidebar toggle. Layout props provide a way to define defaults in your layout and override them from any page.

### Defining Defaults

Layout props are defined as regular component props with default values.

:::tabs key:frameworks

== Vue

```vue
<script setup>
const props = withDefaults(defineProps<{
    title?: string
    showSidebar?: boolean
}>(), {
    title: 'My App',
    showSidebar: true,
})
</script>

<template>
  <header>{{ title }}</header>
  <aside v-if="showSidebar">Sidebar</aside>
  <main>
    <slot />
  </main>
</template>
```

== React

```jsx
export default function Layout({
  title = 'My App',
  showSidebar = true,
  children,
}) {
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
  let { title = 'My App', showSidebar = true, children } = $props()
</script>

<header>{title}</header>
{#if showSidebar}
  <aside>Sidebar</aside>
{/if}
<main>
  {@render children()}
</main>
```

:::

### Static Props

You may pass static props directly in your persistent layout definition using a tuple. These props are set once when the layout is defined and don't change between page navigations.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import Layout from './Layout'

defineProps({ user: Object })
defineOptions({
  layout: [Layout, { title: 'Dashboard' }],
})
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

### Callback Props

Sometimes layout props need to be derived from the current page's props. A callback function receives the page props and returns a layout definition with computed static props.

:::tabs key:frameworks

== Vue

```vue
<script setup>
import Layout from './Layout'

defineOptions({
  layout: (props) => [Layout, { title: 'Profile: ' + props.auth.user.name }],
})
</script>

<template>
  <h1>Profile</h1>
</template>
```

== React

```jsx
import Layout from './Layout'

const Profile = () => {
  return <h1>Profile</h1>
}

Profile.layout = (props) => [
  Layout,
  { title: 'Profile: ' + props.auth.user.name },
]

export default Profile
```

== Svelte

```svelte
<script module>
  import Layout from './Layout.svelte'

  export const layout = (props) => [
    Layout,
    { title: 'Profile: ' + props.auth.user.name },
  ]
</script>

<h1>Profile</h1>
```

:::

The callback receives the page's props and may return any valid layout format: a single component, a tuple with static props, an array for nested layouts, or a named layout object. TypeScript users may use the [`LayoutCallback`](/guide/typescript#layout-callbacks) type for type safety.

#### Returning Props Only

When a [default layout](#default-layouts) is configured in `createInertiaApp`, callbacks may return a plain props object instead of a full layout definition. Inertia will automatically use the default layout and merge the returned props onto it.

:::tabs key:frameworks

== Vue

```vue
<script setup>
defineOptions({
  layout: (props) => ({
    title: 'Profile: ' + props.auth.user.name,
    showSidebar: false,
  }),
})
</script>

<template>
  <h1>Profile</h1>
</template>
```

== React

```jsx
const Profile = () => {
  return <h1>Profile</h1>
}

Profile.layout = (props) => ({
  title: 'Profile: ' + props.auth.user.name,
  showSidebar: false,
})

export default Profile
```

== Svelte

```svelte
<script module>
  export const layout = (props) => ({
    title: 'Profile: ' + props.auth.user.name,
    showSidebar: false,
  })
</script>

<h1>Profile</h1>
```

:::

A static object may also be used when the props don't depend on page data.

```js
Dashboard.layout = { title: 'Dashboard', showSidebar: true }
```

### Dynamic Props

You may also update layout props dynamically from any page component using the `setLayoutProps` function. TypeScript users may [type these props](/guide/typescript#layout-props) globally.

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

### Targeting Named Layouts

[Nested layouts](#nested-layouts) may also be defined as a named object instead of an array, allowing you to target specific layouts with props.

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

You may target a specific named layout by passing the layout name as the first argument to `setLayoutProps`.

:::tabs key:frameworks

== Vue

```js
import { setLayoutProps } from '@inertiajs/vue3'

setLayoutProps('sidebar', {
  collapsed: true,
})
```

== React

```js
import { setLayoutProps } from '@inertiajs/react'

setLayoutProps('sidebar', {
  collapsed: true,
})
```

== Svelte

```js
import { setLayoutProps } from '@inertiajs/svelte'

setLayoutProps('sidebar', {
  collapsed: true,
})
```

:::

[Nested layouts](#nested-layouts) and named layouts may also include static props using the tuple syntax.

```js
// Nested layouts with static props
Dashboard.layout = [
  [AppLayout, { title: 'Dashboard' }],
  [ContentLayout, { padding: 'sm' }],
]

// Named layouts with static props
Dashboard.layout = {
  app: [AppLayout, { theme: 'dark' }],
  content: [ContentLayout, { padding: 'sm' }],
}
```

### Merge Priority

Layout props are resolved from multiple sources with the following priority (highest to lowest):

1. **Dynamic props** - set via `setLayoutProps()`
2. **Static props** - defined in the persistent layout definition (including [callback props](#callback-props))
3. **Defaults** - declared as default values on the layout component's props

### Auto-Reset on Navigation

Dynamic layout props are automatically reset when navigating to a new page (unless `preserveState` is enabled). This ensures each page starts with a clean slate and only the layout props explicitly set by that page are applied.

### Resetting Props

You may also manually reset all dynamic layout props using `resetLayoutProps`.

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
