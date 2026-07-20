# Inertia Modal

[Inertia Modal](https://inertiaui.com/inertia-modal) is a powerful library that enables you to render any Inertia page
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
- Prefetch support for faster modal loading
- Native HTML dialog support for better accessibility
- TypeScript type definitions included
- Highly configurable

While you can use Inertia Modal without changes on the backend, we recommend using the Rails gem
[`inertia_rails-contrib`](https://github.com/skryukov/inertia_rails-contrib) to enhance your modals with base URL support. This ensures that your modals are accessible,
SEO-friendly, and provide a better user experience.

> [!NOTE]
> Svelte is not supported by Inertia Modal.

## Requirements

- React 19+ with `@inertiajs/react` 3.0+, or Vue 3.4+ with `@inertiajs/vue3` 3.0+ — Inertia Modal's major
  version follows the Inertia.js version it supports, so on Inertia.js v2, install Inertia Modal 2.x and
  follow the [2.x documentation](https://inertiaui.com/inertia-modal/docs/v2/introduction) instead
- Tailwind CSS 4 for the default modal UI. If you're on Tailwind CSS 3 (or don't use Tailwind at all), you can
  still use Inertia Modal in [headless mode](https://inertiaui.com/inertia-modal/docs/headless-mode) with your own UI.
- For base URL support: [`inertia_rails-contrib`](https://github.com/skryukov/inertia_rails-contrib) 0.6+

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

Inertia Modal 3.0+ comes with TypeScript support.

### 2. Configure Inertia

Update your Inertia app setup to mount the modal root component:

:::tabs key:frameworks
== Vue

```js
// app/frontend/entrypoints/inertia.js
import { createInertiaApp } from '@inertiajs/vue3'
import { withInertiaModal } from '@inertiaui/modal-vue' // [!code ++]

createInertiaApp({
  pages: '../pages',
  // [!code ++:3]
  withApp(app) {
    withInertiaModal(app)
  },
})
```

== React

```jsx
// app/frontend/entrypoints/inertia.jsx
import { createInertiaApp } from '@inertiajs/react'
import { ModalStackProvider, ModalRoot } from '@inertiaui/modal-react' // [!code ++]

// [!code ++:8]
function ModalLayout({ children }) {
  return (
    <>
      {children}
      <ModalRoot />
    </>
  )
}

createInertiaApp({
  pages: '../pages',
  withApp: (app) => <ModalStackProvider>{app}</ModalStackProvider>, // [!code ++]
  layout: () => ModalLayout, // [!code ++]
})
```

:::

> [!NOTE]
> If your app already defines a `setup` callback, per-page layouts, or a `layout` option in `createInertiaApp`,
> render `<ModalRoot />` inside your existing layout component instead. See the
> [Custom App Mounting](https://inertiaui.com/inertia-modal/docs/custom-app-mounting) documentation for details.

> [!TIP]
> In a TypeScript app, annotate the layout's `children` prop:
> `function ModalLayout({ children }: { children: React.ReactNode })`.

### 3. Tailwind CSS Configuration

The default modal UI is built for Tailwind CSS 4. Tell Tailwind to scan the package's source files by adding an
`@source` directive to your CSS entrypoint:

:::tabs key:frameworks
== Vue

```css
/* app/frontend/entrypoints/application.css */
@source '../../../node_modules/@inertiaui/modal-vue/src';
```

== React

```css
/* app/frontend/entrypoints/application.css */
@source '../../../node_modules/@inertiaui/modal-react/src';
```

:::

> [!WARNING]
> The path must point to the `src` directory inside the package and must be relative to the CSS file itself.
> If your CSS entrypoint is located elsewhere, adjust the number of `../` segments accordingly, otherwise
> the modal will render without styles.

If you're on Tailwind CSS 3, the default UI is not supported — use
[headless mode](https://inertiaui.com/inertia-modal/docs/headless-mode) and provide your own markup.

### 4. Add the Ruby Gem (optional but recommended)

Install the [`inertia_rails-contrib`](https://github.com/skryukov/inertia_rails-contrib) gem to your Rails application
to enable base URL support for modals:

```bash
bundle add inertia_rails-contrib
```

Then, enable the InertiaUI Modal integration in an initializer:

```ruby
# config/initializers/inertia_rails_contrib.rb
InertiaRailsContrib.configure do |config|
  config.enable_inertia_ui_modal = true
end
```

## Basic example

The package comes with two components: `Modal` and `ModalLink`. `ModalLink` is very similar to Inertia's [built-in
`Link` component](/guide/links), but it opens the linked route in a modal instead of a full page load. So, if you have a
link that you want to open in a modal, you can simply replace `Link` with `ModalLink`.

:::tabs key:frameworks
== Vue

```vue
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

```jsx
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

```vue
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

```jsx
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
    render inertia: { # [!code --]
    render inertia_modal: { # [!code ++]
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
    render inertia_modal: {
      user:,
      roles: -> { Role.all },
    } # [!code --]
    }, base_url: users_path # [!code ++]
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

```vue
<template>
  <ModalLink navigate href="/users/create"> Create User </ModalLink>
</template>
```

== React

```jsx
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
