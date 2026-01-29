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

## Global configuration

You may configure Inertia's types globally by augmenting the `InertiaConfig` interface in the `@inertiajs/core` module. This is typically done in a `global.d.ts` file in your project's root or `types` directory.

```ts
// global.d.ts
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
  }
}
```

> [!NOTE]
> For module augmentation to work, your `tsconfig.json` needs to include `.d.ts` files. Make sure a pattern like `"app/frontend/**/*.d.ts"` is present in the `include` array, adjusted to match your project's directory structure.

### Shared page props

The `sharedPageProps` option defines the type of data that is [shared](/guide/shared-data) with every page in your application. With this configuration, `page.props.auth` and `page.props.appName` will be properly typed everywhere.

```ts
sharedPageProps: {
  auth: { user: { id: number; name: string } | null }
  appName: string
}
```

### Flash data

The `flashDataType` option defines the type of [flash data](/guide/flash-data) in your application.

```ts
flashDataType: {
  toast?: { type: 'success' | 'error'; message: string }
}
```

### Error values

By default, validation error values are typed as `string`. You may configure TypeScript to expect arrays instead for Rails' default (with `model.errors`) — multiple errors per field.

```ts
errorValueType: string[]
```

## Page components

You may type the `import.meta.glob` result for better type safety when resolving page components.

:::tabs key:frameworks
== Vue

```ts
import { createInertiaApp } from '@inertiajs/vue3'
import type { DefineComponent } from 'vue'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob<DefineComponent>('../pages/**/*.vue', {
      eager: true,
    })
    return pages[`../pages/${name}.vue`]
  },
  // ...
})
```

== React

```tsx
import { createInertiaApp, type ResolvedComponent } from '@inertiajs/react'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob<ResolvedComponent>('../pages/**/*.tsx', {
      eager: true,
    })
    return pages[`../pages/${name}.tsx`]
  },
  // ...
})
```

== Svelte 4|Svelte 5

```ts
import { createInertiaApp, type ResolvedComponent } from '@inertiajs/svelte'

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob<ResolvedComponent>('../pages/**/*.svelte', {
      eager: true,
    })
    return pages[`../pages/${name}.svelte`]
  },
  // ...
})
```

:::

## Page props

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

== Svelte 4|Svelte 5

```svelte
<script lang="ts">
  import { usePage } from '@inertiajs/svelte'

  const page = usePage<{
    posts: { id: number; title: string }[]
  }>()
</script>
```

:::

## Form helper

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

== Svelte 4|Svelte 5

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

### Nested data and arrays

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

## Remembering state

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

== Svelte 4|Svelte 5

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

## Restoring state

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

## Router requests

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

## Scoped flash data

The `router.flash()` method accepts a generic for typing page or section-specific flash data, separate from the global `flashDataType` configuration.

```ts
import { router } from '@inertiajs/react'

router.flash<{ paymentError: string }>({ paymentError: 'Card declined' })
```

## Client-side visits

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
