# Title & Meta

Since Inertia powered JavaScript apps are rendered within the document `<body>`, they are unable to render markup to the document `<head>`, as it's outside of their scope. To help with this, Inertia ships with a `<Head>` component which can be used to set the page `<title>`, `<meta>` tags, and other `<head>` elements.

The `<Head>` component will only replace `<head>` elements that are not in your root layout.

> [!NOTE]
> Since v3.10.0, Inertia Rails supports managing meta tags via Rails. This allows your meta tags to work with link preview services without setting up server-side rendering. Since this isn't a part of the Inertia.js core, it's documented in the [server driven meta tags cookbook](/cookbook/server-managed-meta-tags).

The `<Head>` component is not available in the Svelte adapter, as Svelte already ships with its own `<svelte:head>` component.

## Head Component

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

== Svelte

```svelte
<svelte:head>
  <title>Your page title</title>
  <meta name="description" content="Your page description" />
</svelte:head>
```

:::

## Title Shorthand

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

== Svelte

```js
// Not supported
```

:::

## Title Callback

You can globally modify the page `<title>` using the `title` callback in the `createInertiaApp` setup method. Typically, this method is invoked in your application's main JavaScript file. A common use case for the title callback is automatically adding an app name before or after each page title.

```js
createInertiaApp({
  title: (title) => `${title} - My App`,
  // ...
})
```

After defining the `title` callback, the callback will automatically be invoked when you set a title using the `<Head>` component.

> [!NOTE]
> When using [server driven meta tags](/cookbook/server-managed-meta-tags), configure the [title template](/cookbook/server-managed-meta-tags#title-template) on the server instead — the client applies the `title` callback on top of server-provided titles, so combining the two would apply the suffix twice.

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

== Svelte

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

== Svelte

```js
// Not supported
```

:::

Without [SSR](/guide/server-side-rendering), the callback only runs in the browser. Link previews (like in Slack) don't run JavaScript, so they show the `<title>` from your Rails layout instead. To set that title, see [Default Title](/guide/responses#default-title).

## Multiple Head Instances

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

== Svelte

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

## Head Extension

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
// AppHead.js

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

== Svelte

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

== Svelte

```js
// Not supported
```

:::

## Server-Side Head Elements

You may wish to include default head elements like `<title>` or `<meta>` tags in your root layout. This creates two challenges: preventing duplicates when [SSR](/guide/server-side-rendering) is active, and ensuring the client-side `<Head>` component may replace them during navigation.

### SSR Fallback

@available_since rails=master

`inertia_ssr_head` accepts fallback content in a block. The block renders only when the response isn't server-side rendered. When SSR is active, the `<Head>` component already provides these elements as part of the server-rendered response, so the fallback is skipped.

```erb
<%# app/views/layouts/application.html.erb %>
<head>
  <%= inertia_ssr_head do %>
    <title>My App</title>
    <meta data-inertia="description" name="description" content="My application description">
  <% end %>
  <%= vite_javascript_tag 'application' %>
</head>
```

If you only need a fallback `<title>`, use the [`default_title`](/guide/responses#default-title) option of `inertia_meta_tags` instead.

### The `data-inertia` Attribute

@available_since core=2.2.13

The client-side `<Head>` component tracks the elements it manages by marking them with a `data-inertia` attribute. By default, it leaves any other tags in your root layout untouched. Since there may only be one `<title>` tag, the `<Head>` component will always replace it. Other elements like `<meta>` and `<link>` may have multiple instances, so the component needs a way to identify which ones it should manage.

You may add the `data-inertia` attribute to elements in your root layout to have the `<Head>` component adopt them. On the first client-side navigation, it will match these elements by key and replace or remove them as needed.

```erb
<%# app/views/layouts/application.html.erb %>
<head>
  <title>My App</title>
  <meta data-inertia="description" name="description" content="My application description">
  <%= vite_javascript_tag 'application' %>
</head>
```

The `data-inertia` value corresponds to the `head-key` property on your client-side `<Head>` elements.

Meta tags rendered by Inertia Rails use the older `inertia` attribute unless you enable the [`use_data_inertia_head_attribute`](/guide/configuration#use-data-inertia-head-attribute) or [`server_head`](/guide/configuration#server-head) option. Inertia.js v3 clients only recognize `data-inertia`, so the Rails generator enables this option.

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.use_data_inertia_head_attribute = true
end
```

Inertia.js v2 clients use the `inertia` attribute by default. To switch them to `data-inertia`, enable the `future.useDataInertiaHeadAttribute` option in your [application defaults](/guide/client-side-setup#configuring-defaults):

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
