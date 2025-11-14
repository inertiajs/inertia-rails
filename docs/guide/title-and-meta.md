# Title & meta

Since Inertia powered JavaScript apps are rendered within the document `<body>`, they are unable to render markup to the document `<head>`, as it's outside of their scope. To help with this, Inertia ships with a `<Head>` component which can be used to set the page `<title>`, `<meta>` tags, and other `<head>` elements.

> [!NOTE]
> Since v3.10.0, Inertia Rails supports managing meta tags via Rails. This allows your meta tags to work with link preview services without setting up server-side rendering. Since this isn't a part of the Inertia.js core, it's documented in the [server driven meta tags cookbook](/cookbook/server-managed-meta-tags).

> [!NOTE]
> The `<Head>` component will only replace `<head>` elements that are not in your server-side layout.

> [!NOTE]
> The `<Head>` component is not available in the Svelte adapter, as Svelte already ships with its own `<svelte:head>` component.

## Head component

To add `<head>` elements to your page, use the `<Head>` component. Within this component, you can include the elements that you wish to add to the document `<head>`.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { Head } from '@inertiajs/vue3'
</script>

<template>
  <Head>
    <title>Your page title</title>
    <meta name="description" content="Your page description" />
  </Head>
</template>
```

== React

```jsx
import { Head } from '@inertiajs/react'

export default () => (
  <Head>
    <title>Your page title</title>
    <meta name="description" content="Your page description" />
  </Head>
)
```

== Svelte 4|Svelte 5

```svelte
<svelte:head>
  <title>Your page title</title>
  <meta name="description" content="Your page description" />
</svelte:head>
```

> [!NOTE]
> The `<svelte:head>` component is provided by Svelte.

:::

Title shorthand

If you only need to add a `<title>` to the document `<head>`, you may simply pass the title as a prop to the `<Head>` component.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { Head } from '@inertiajs/vue3'
</script>

<template>
  <Head title="Your page title" />
</template>
```

== React

```jsx
import { Head } from '@inertiajs/react'

export default () => <Head title="Your page title" />
```

== Svelte 4|Svelte 5

```js
// Not supported
```

:::

## Title callback

You can globally modify the page `<title>` using the title callback in the `createInertiaApp` setup method. Typically, this method is invoked in your application's main JavaScript file. A common use case for the title callback is automatically adding an app name before or after each page title.

```js
createInertiaApp({
  title: (title) => `${title} - My App`,
  // ...
})
```

After defining the title callback, the callback will automatically be invoked when you set a title using the `<Head>` component.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { Head } from '@inertiajs/vue3'
</script>

<template>
  <Head title="Home" />
</template>
```

== React

```jsx
import { Head } from '@inertiajs/react'

export default () => <Head title="Home" />
```

== Svelte 4|Svelte 5

```js
// Not supported
```

:::

Which, in this example, will result in the following `<title>` tag.

```html
<title>Home - My App</title>
```

The `title` callback will also be invoked when you set the title using a `<title>` tag within your `<Head>` component.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { Head } from '@inertiajs/vue3'
</script>

<template>
  <Head>
    <title>Home</title>
  </Head>
</template>
```

== React

```jsx
import { Head } from '@inertiajs/react'

export default () => (
  <Head>
    <title>Home</title>
  </Head>
)
```

== Svelte 4|Svelte 5

```js
// Not supported
```

:::

# Multiple Head instances

It's possible to have multiple instances of the `<Head>` component throughout your application. For example, your layout can set some default `<Head>` elements, and then your individual pages can override those defaults.

:::tabs key:frameworks
== Vue

```vue
<!-- Layout.vue -->
<script setup>
import { Head } from '@inertiajs/vue3'
</script>

<template>
  <Head>
    <title>My app</title>
    <meta
      head-key="description"
      name="description"
      content="This is the default description"
    />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
  </Head>
</template>

<!-- About.vue -->
<script setup>
import { Head } from '@inertiajs/vue3'
</script>

<template>
  <Head>
    <title>About - My app</title>
    <meta
      head-key="description"
      name="description"
      content="This is a page specific description"
    />
  </Head>
</template>
```

== React

```jsx
// Layout.jsx
import { Head } from '@inertiajs/react'

export default () => (
  <Head>
    <title>My app</title>
    <meta
      head-key="description"
      name="description"
      content="This is the default description"
    />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
  </Head>
)

// About.jsx
import { Head } from '@inertiajs/react'

export default () => (
  <Head>
    <title>About - My app</title>
    <meta
      head-key="description"
      name="description"
      content="This is a page specific description"
    />
  </Head>
)
```

== Svelte 4|Svelte 5

```js
// Not supported
```

:::

Inertia will only ever render one `<title>` tag; however, all other tags will be stacked since it's valid to have multiple instances of them. To avoid duplicate tags in your `<head>`, you can use the `head-key` property, which will make sure the tag is only rendered once. This is illustrated in the example above for the `<meta name="description">` tag.

The code example above will render the following HTML.

```html
<head>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
  <title>About - My app</title>
  <meta name="description" content="This is a page specific description" />
</head>
```

### Head extension

When building a real application, it can sometimes be helpful to create a custom head component that extends Inertia's `<Head>` component. This gives you a place to set app-wide defaults, such as appending the app name to the page title.

:::tabs key:frameworks
== Vue

```vue
<!-- AppHead.vue -->
<script setup>
import { Head } from '@inertiajs/vue3'

defineProps({ title: String })
</script>

<template>
  <Head :title="title ? `${title} - My App` : 'My App'">
    <slot />
  </Head>
</template>
```

== React

```jsx
// AppHead.jsx
import { Head } from '@inertiajs/react'

export default ({ title, children }) => {
  return (
    <Head>
      <title>{title ? `${title} - My App` : 'My App'}</title>
      {children}
    </Head>
  )
}
```

== Svelte 4|Svelte 5

```js
// Not supported
```

:::

Once you have created the custom component, you can just start using it in your pages.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import AppHead from './AppHead'
</script>

<template>
  <AppHead title="About" />
</template>
```

== React

```jsx
import AppHead from './AppHead'

export default () => <AppHead title="About" />
```

== Svelte 4|Svelte 5

```js
// Not supported
```

:::

## Inertia attribute on elements

Inertia has historically used the `inertia` attribute to track and manage elements in the document `<head>`. However, you can now opt-in to using the more standards-compliant `data-inertia` attribute instead. According to the HTML specification, custom attributes should be prefixed with `data-` to avoid conflicts with future HTML standards.

To enable this, configure the `future.useDataInertiaHeadAttribute` option in your [application defaults](/guide/client-side-setup#configuring-defaults).

```js
createInertiaApp({
  // resolve, setup, etc.
  defaults: {
    future: {
      useDataInertiaHeadAttribute: true,
    },
  },
})
```
