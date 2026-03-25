# TypeScript

Inertia provides first-class TypeScript support. You may configure global types using declaration merging, and pass generics to hooks and router methods for type-safe props, forms, and state management.

## Using pnpm

Due to pnpm's strict dependency isolation, `@inertiajs/core` is not accessible at `node_modules/@inertiajs/core`. Instead, it's nested inside `.pnpm/`, which prevents TypeScript module augmentation from resolving the module.

You may fix this by configuring pnpm to [hoist the package](https://pnpm.io/settings#publichoistpattern). Add the following to your `.npmrc` file and run `pnpm install`.

```ini
public-hoist-pattern[]=@inertiajs/core
```

Alternatively, you may add `@inertiajs/core` as a direct dependency in your project.

```bash
pnpm add @inertiajs/core
```

## Global Configuration

You may configure Inertia's types globally by augmenting the `InertiaConfig` interface in the `@inertiajs/core` module. This is typically done in a `global.d.ts` file in your project's root or `types` directory.

```ts
// global.d.ts
import '@inertiajs/core'

declare module '@inertiajs/core' {
  export interface InertiaConfig {
    sharedPageProps: {
      auth: { user: { id: number; name: string } | null }
      appName: string
    }
    flashDataType: {
      toast?: { type: 'success' | 'error'; message: string }
    }
    errorValueType: string[]
    layoutProps: {
      title: string
      showSidebar: boolean
    }
    namedLayoutProps: {
      app: { title: string; theme: 'light' | 'dark' }
      content: { padding: string; maxWidth: string }
    }
  }
}
```

> [!NOTE]
> The `import` statement (or `export {}`) is required to make this file a module. Without it, `declare module` replaces the module definition instead of augmenting it. Your `tsconfig.json` also needs to include `.d.ts` files, so make sure a pattern like `"@/**/*.d.ts"` is present in the `include` array.

### Shared Page Props

The `sharedPageProps` option defines the type of data that is [shared](/guide/shared-data) with every page in your application. With this configuration, `page.props.auth` and `page.props.appName` will be properly typed everywhere.

```ts
sharedPageProps: {
  auth: { user: { id: number; name: string } | null }
  appName: string
}
```

### Flash Data

The `flashDataType` option defines the type of [flash data](/guide/flash-data) in your application.

```ts
flashDataType: {
  toast?: { type: 'success' | 'error'; message: string }
}
```

### Error Values

By default, validation error values are typed as `string`. You may configure TypeScript to expect arrays instead for Rails' default (with `model.errors`) — multiple errors per field.

```ts
errorValueType: string[]
```

### Layout Props

The `layoutProps` option types the data accepted by `setLayoutProps()`. The `namedLayoutProps` option types the data accepted by `setLayoutProps('name', props)`, keyed by layout name.

```ts
layoutProps: {
  title: string
  showSidebar: boolean
}
namedLayoutProps: {
  app: {
    title: string
    theme: 'light' | 'dark'
  }
  content: {
    padding: string
    maxWidth: string
  }
}
```

With this configuration, `setLayoutProps({ title: 'Dashboard' })` is type-checked, and `setLayoutProps('app', { theme: 'dark' })` validates both the layout name and its props.

You may also pass a generic type parameter directly to `setLayoutProps` for ad-hoc typing without configuring the global `InertiaConfig` interface.

```ts
setLayoutProps<{ custom: string }>({ custom: 'value' })
setLayoutProps<{ collapsed: boolean }>('sidebar', { collapsed: true })
```

## Page Components

You may type the `import.meta.glob` result for better type safety when resolving page components.

:::tabs key:frameworks

== Vue

```ts
import { createInertiaApp } from '@inertiajs/vue3'
import type { DefineComponent } from 'vue'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob<DefineComponent>('../pages/**/*.vue')
    return pages[`../pages/${name}.vue`]()
  },
  // ...
})
```

== React

```tsx
import { createInertiaApp, type ResolvedComponent } from '@inertiajs/react'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob<ResolvedComponent>('../pages/**/*.tsx')
    return pages[`../pages/${name}.tsx`]()
  },
  // ...
})
```

== Svelte

```ts
import { createInertiaApp, type ResolvedComponent } from '@inertiajs/svelte'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob<ResolvedComponent>('../pages/**/*.svelte')
    return pages[`../pages/${name}.svelte`]()
  },
  // ...
})
```

:::

## Page Props

You may type page-specific props by passing a generic to `usePage()`. These are merged with your global `sharedPageProps`, giving you autocomplete and type checking for both shared and page-specific data.

:::tabs key:frameworks

== Vue

```vue
<script setup lang="ts">
import { usePage } from '@inertiajs/vue3'

const page = usePage<{
  posts: { id: number; title: string }[]
}>()
</script>
```

== React

```tsx
import { usePage } from '@inertiajs/react'

export default function Posts() {
  const page = usePage<{
    posts: { id: number; title: string }[]
  }>()

  return (
    <ul>
      {page.props.posts.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  )
}
```

== Svelte

```svelte
<script lang="ts">
  import { usePage } from '@inertiajs/svelte'

  const page = usePage<{
    posts: { id: number; title: string }[]
  }>()
</script>
```

:::

## Form Helper

The [form helper](/guide/forms#form-helper) accepts a generic type parameter for type-safe form data and error handling. This provides autocomplete for form fields and errors, and prevents typos in field names.

:::tabs key:frameworks

== Vue

```vue
<script setup lang="ts">
import { useForm } from '@inertiajs/vue3'

const form = useForm<{
  name: string
  email: string
  company: { name: string }
}>({
  name: '',
  email: '',
  company: { name: '' },
})
</script>
```

== React

```tsx
import { useForm } from '@inertiajs/react'

export default function CreateUser() {
  const form = useForm<{
    name: string
    email: string
    company: { name: string }
  }>({
    name: '',
    email: '',
    company: { name: '' },
  })

  return null
}
```

== Svelte

```svelte
<script lang="ts">
  import { useForm } from '@inertiajs/svelte'

  const form = useForm<{
    name: string
    email: string
    company: { name: string }
  }>({
    name: '',
    email: '',
    company: { name: '' },
  })
</script>
```

:::

### Nested Data and Arrays

Form types fully support nested objects and arrays. You may access and update nested fields using dot notation, and error keys are automatically typed to match.

```ts
import { useForm } from '@inertiajs/react'

const form = useForm<{
  user: { name: string; email: string }
  tags: { id: number; label: string }[]
}>({
  user: { name: '', email: '' },
  tags: [],
})
```

## Form Component

@available_since core=3.0.0

The `<Form>` component accepts a generic type parameter for type-safe slot props. In React, you may pass the generic directly. In Vue and Svelte, you may use the `createForm` helper to create a typed form component.

:::tabs key:frameworks

== Vue

```vue
<script setup lang="ts">
import { createForm } from '@inertiajs/vue3'

interface UserForm {
  name: string
  email: string
}

const TypedForm = createForm<UserForm>()
</script>

<template>
  <TypedForm action="/users" method="post" #default="{ errors }">
    <input type="text" name="name" />
    <div v-if="errors.name">{{ errors.name }}</div>
    <button type="submit">Create User</button>
  </TypedForm>
</template>
```

== React

```tsx
import { Form } from '@inertiajs/react'

interface UserForm {
  name: string
  email: string
}

export default function CreateUser() {
  return (
    <Form<UserForm> action="/users" method="post">
      {({ errors }) => (
        <>
          <input type="text" name="name" />
          {errors.name && <div>{errors.name}</div>}
          <button type="submit">Create User</button>
        </>
      )}
    </Form>
  )
}
```

== Svelte

```svelte
<script lang="ts">
  import { createForm } from '@inertiajs/svelte'

  interface UserForm {
    name: string
    email: string
  }

  const TypedForm = createForm<UserForm>()
</script>

<TypedForm action="/users" method="post">
  {#snippet children({ errors })}
    <input type="text" name="name" />
    {#if errors.name}<div>{errors.name}</div>{/if}
    <button type="submit">Create User</button>
  {/snippet}
</TypedForm>
```

:::

The generic provides autocomplete and type checking for the `errors` object, `setError`, `clearErrors`, and other slot props that reference form fields.

### useFormContext

@available_since core=3.0.0

The `useFormContext()` function also accepts a generic type parameter, providing type-safe access to the form context from child components.

:::tabs key:frameworks

== React

```tsx
import { useFormContext } from '@inertiajs/react'

const form = useFormContext<UserForm>()
```

== Vue

```vue
<script setup lang="ts">
import { useFormContext } from '@inertiajs/vue3'

const form = useFormContext<UserForm>()
</script>
```

== Svelte

```svelte
<script lang="ts">
  import { useFormContext } from '@inertiajs/svelte'

  const form = useFormContext<UserForm>()
</script>
```

:::

## HTTP Helper

The [`useHttp`](/guide/http-requests) hook accepts two generic type parameters: the form data type and an optional default response type.

```ts
import { useHttp } from '@inertiajs/react'

interface UserForm {
  name: string
  email: string
}

interface UserResponse {
  id: number
  name: string
}

const http = useHttp<UserForm, UserResponse>({ name: '', email: '' })
```

### Per-Request Response Types

Each HTTP method accepts its own generic type parameter, allowing you to override the response type on a per-call basis. This is useful when different endpoints return different response shapes.

```ts
interface OrderResponse {
  orderId: string
  total: number
}

// Override the response type per request...
const user: UserResponse = await http.post<UserResponse>('/api/users')
const order: OrderResponse = await http.get<OrderResponse>('/api/orders/123')
const submitted: UserResponse = await http.submit<UserResponse>(
  'post',
  '/api/users',
)

// The onSuccess callback is also typed...
await http.post<UserResponse>('/api/users', {
  onSuccess: (response) => {
    console.log(response.id, response.name)
  },
})
```

## Remembering State

The `useRemember` hook accepts a generic type parameter for type-safe local state persistence, providing autocomplete and ensuring values match the expected types.

:::tabs key:frameworks

== Vue

```vue
<script setup lang="ts">
import { useRemember } from '@inertiajs/vue3'

const filters = useRemember<{
  search: string
  status: 'active' | 'inactive' | 'all'
}>({
  search: '',
  status: 'all',
})
</script>
```

== React

```tsx
import { useRemember } from '@inertiajs/react'

export default function Users() {
  const [filters, setFilters] = useRemember<{
    search: string
    status: 'active' | 'inactive' | 'all'
  }>({
    search: '',
    status: 'all',
  })

  return null
}
```

== Svelte

```svelte
<script lang="ts">
  import { useRemember } from '@inertiajs/svelte'

  const filters = useRemember<{
    search: string
    status: 'active' | 'inactive' | 'all'
  }>({
    search: '',
    status: 'all',
  })
</script>
```

:::

## Restoring State

The `router.restore()` method accepts a generic for typing state restored from [history](/guide/remembering-state#manually-saving-state).

```ts
import { router } from '@inertiajs/react'

interface TableState {
  sortBy: string
  sortDesc: boolean
  page: number
}

const restored = router.restore<TableState>('table-state')

if (restored) {
  console.log(restored.sortBy)
}
```

## Router Requests

Router methods accept a generic for typing request data, providing type checking for the data being sent.

```ts
import { router } from '@inertiajs/react'

interface CreateUserData {
  name: string
  email: string
}

router.post<CreateUserData>('/users', {
  name: 'John',
  email: 'john@example.com',
})
```

## Scoped Flash Data

The `router.flash()` method accepts a generic for typing page or section-specific flash data, separate from the global `flashDataType` configuration.

```ts
import { router } from '@inertiajs/react'

router.flash<{ paymentError: string }>({ paymentError: 'Card declined' })
```

## Client-Side Visits

The `router.push()` and `router.replace()` methods accept a generic for typing [client-side visit](/guide/manual-visits#client-side-visits) props.

```ts
import { router } from '@inertiajs/react'

interface UserPageProps {
  user: { id: number; name: string }
}

router.push<UserPageProps>({
  component: 'Users/Show',
  url: '/users/1',
  props: { user: { id: 1, name: 'John' } },
})

router.replace<UserPageProps>({
  props: (current) => ({
    ...current,
    user: { ...current.user, name: 'Updated' },
  }),
})
```
