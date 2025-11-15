# Inertia Modal

[Inertia Modal](https://github.com/inertiaui/modal) is a powerful library that enables you to render any Inertia page
as a modal dialog. It seamlessly integrates with your existing Inertia Rails application, allowing you to create modal
workflows without the complexity of managing modal state manually.

Here's a summary of the features:

- Supports React and Vue
- Zero backend configuration
- Super simple frontend API
- Support for Base Route / URL
- Modal and slideover support
- Headless support
- Nested/stacked modals support
- Reusable modals
- Multiple sizes and positions
- Reload props in modals
- Easy communication between nested/stacked modals
- Highly configurable

While you can use Inertia Modal without changes on the backend, we recommend using the Rails gem
[`inertia_rails-contrib`](https://github.com/skryukov/inertia_rails-contrib) to enhance your modals with base URL support. This ensures that your modals are accessible,
SEO-friendly, and provide a better user experience.

> [!NOTE]
> Svelte 5 is not yet supported by Inertia Modal.

## Installation

### 1. Install the NPM Package

:::tabs key:frameworks
== Vue

```bash
npm install @inertiaui/modal-vue
```

== React

```bash
npm install @inertiaui/modal-react
```

:::

### 2. Configure Inertia

Update your Inertia app setup to include the modal plugin:

:::tabs key:frameworks
== Vue

```js twoslash
// frontend/entrypoints/inertia.js
import { createApp, h } from 'vue'
import { createInertiaApp } from '@inertiajs/vue3'
import { renderApp } from '@inertiaui/modal-vue' // [!code ++]

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.vue', { eager: true })
    return pages[`../pages/${name}.vue`]
  },
  setup({ el, App, props, plugin }) {
    createApp({ render: () => h(App, props) }) // [!code --]
    createApp({ render: renderApp(App, props) }) // [!code ++]
      .use(plugin)
      .mount(el)
  },
})
```

== React

```js twoslash
// frontend/entrypoints/inertia.js
import { createInertiaApp } from '@inertiajs/react'
import { createElement } from 'react' // [!code --]
import { renderApp } from '@inertiaui/modal-react' // [!code ++]
import { createRoot } from 'react-dom/client'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.jsx', { eager: true })
    return pages[`../pages/${name}.jsx`]
  },
  setup({ el, App, props }) {
    const root = createRoot(el)
    root.render(createElement(App, props)) // [!code --]
    root.render(renderApp(App, props)) // [!code ++]
  },
})
```

:::

### 3. Tailwind CSS Configuration

:::tabs key:frameworks
== Vue

For Tailwind CSS v4, add the modal styles to your CSS:

```css
/* app/entrypoints/frontend/application.css */
@source "../../../node_modules/@inertiaui/modal-vue";
```

For Tailwind CSS v3, update your `tailwind.config.js`:

```js twoslash
export default {
  content: [
    './node_modules/@inertiaui/modal-vue/src/**/*.{js,vue}',
    // other paths...
  ],
}
```

== React

For Tailwind CSS v4, add the modal styles to your CSS:

```css
/* app/entrypoints/frontend/application.css */
@source "../../../node_modules/@inertiaui/modal-react";
```

For Tailwind CSS v3, update your `tailwind.config.js`:

```js twoslash
export default {
  content: [
    './node_modules/@inertiaui/modal-react/src/**/*.{js,jsx}',
    // other paths...
  ],
}
```

:::

### 4. Add the Ruby Gem (optional but recommended)

Install the [`inertia_rails-contrib`](https://github.com/skryukov/inertia_rails-contrib) gem to your Rails application to enable base URL support for modals:

```bash
bundle add inertia_rails-contrib
```

## Basic example

The package comes with two components: `Modal` and `ModalLink`. `ModalLink` is very similar to Inertia's [built-in
`Link` component](/guide/links), but it opens the linked route in a modal instead of a full page load. So, if you have a
link that you want to open in a modal, you can simply replace `Link` with `ModalLink`.

:::tabs key:frameworks
== Vue

```vue twoslash
<script setup>
import { Link } from '@inertiajs/vue3' // [!code --]
import { ModalLink } from '@inertiaui/modal-vue' // [!code ++]
</script>

<template>
  <!-- [!code --] -->
  <Link href="/users/create">Create User</Link>
  <!-- [!code ++] -->
  <ModalLink href="/users/create">Create User</ModalLink>
</template>
```

== React

```jsx twoslash
import {Link} from '@inertiajs/react' // [!code --]
import {ModalLink} from '@inertiaui/modal-react' // [!code ++]

export const CreateUserButton = () => {
 return (
   <Link href="/users/create">Create User</Link> // [!code --]
   <ModalLink href="/users/create">Create User</ModalLink> // [!code ++]
 )
}
```

:::

The page you linked can then use the `Modal` component to wrap its content in a modal.

:::tabs key:frameworks
== Vue

```vue twoslash
<script setup>
import { Modal } from '@inertiaui/modal-vue'
</script>

<template>
  <!-- [!code ++] -->
  <Modal>
    <h1>Create User</h1>
    <form>
      <!-- Form fields -->
    </form>
    <!-- [!code ++] -->
  </Modal>
</template>
```

== React

```jsx twoslash
import {Modal} from '@inertiaui/modal-react'

export const CreateUser = () => {
 return (
   {/* [!code --] */}
   <>
   {/* [!code ++] */}
   <Modal>
     <h1>Create User</h1>
     <form>
       {/* Form fields */}
     </form>
     {/* [!code --] */}
   </Modal>
   {/* [!code ++] */}
   </>
 )
}
```

:::

That's it! There is no need to change anything about your routes or controllers!

## Enhanced Usage With Base URL Support

By default, Inertia Modal doesn't change the URL when opening a modal. It just stays on the same page and displays the
modal content. However, you may want to change this behavior and update the URL when opening a modal. This has a few
benefits:

- It allows users to bookmark the modal and share the URL with others.
- The modal becomes part of the browser history, so users can use the back and forward buttons.
- It makes the modal content accessible to search engines (when using [SSR](/guide/server-side-rendering)).
- It allows you to open the modal in a new tab.

> [!NOTE]
> To enable this feature, you need to use the [`inertia_rails-contrib`](https://github.com/skryukov/inertia_rails-contrib) gem, which provides base URL support for modals.

## Define a Base Route

To define the base route for your modal, you need to use the `inertia_modal` renderer in your controller instead of the
`inertia` one. It accepts the same arguments as the `inertia` renderer:

```ruby

class UsersController < ApplicationController
  def edit
    render inertia: 'Users/Edit', props: { # [!code --]
    render inertia_modal: 'Users/Edit', props: { # [!code ++]
      user:,
      roles: -> { Role.all },
    }
  end
end
```

Then, you can pass the `base_url` parameter to the `inertia_modal` renderer to define the base route for your modal:

```ruby

class UsersController < ApplicationController
  def edit
    render inertia_modal: 'Users/Edit', props: {
      user:,
      roles: -> { Role.all },
    } # [!code --]
    }, base_url : users_path # [!code ++]
  end
end
```

> [!WARNING] Reusing the Modal URL with different Base Routes
> The `base_url` parameter acts merely as a fallback when the modal is directly opened using a URL. If you open the
> modal from a different route, the URL will be generated based on the current route.

## Open a Modal with a Base Route

Finally, the frontend needs to know that we're using the browser history to navigate between modals. To do this, you need
to add the `navigate` attribute to the `ModalLink` component:

:::tabs key:frameworks
== Vue

```vue twoslash
<template>
  <ModalLink navigate href="/users/create"> Create User </ModalLink>
</template>
```

== React

```jsx twoslash
export default function UserIndex() {
  return (
    <ModalLink navigate href="/users/create">
      Create User
    </ModalLink>
  )
}
```

:::

Now, when you click the "Create User" link, it will open the modal and update the URL to `/users/create`.

## Further Reading

For advanced usage, configuration options, and additional features, check out [the official Inertia Modal documentation](https://inertiaui.com/inertia-modal/docs).
