# Load when visible

Inertia supports lazy loading data on scroll using the Intersection Observer API. It provides the `WhenVisible` component as a convenient way to load data when an element becomes visible in the viewport.

The `WhenVisible` component accepts a `data` prop that specifies the key of the prop to load. It also accepts a `fallback` prop that specifies a component to render while the data is loading. The `WhenVisible` component should wrap the component that depends on the data.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { WhenVisible } from '@inertiajs/vue3'
</script>

<template>
  <WhenVisible data="permissions">
    <template #fallback>
      <div>Loading...</div>
    </template>
    <div v-for="permission in permissions">
      <!-- ... -->
    </div>
  </WhenVisible>
</template>
```

== React

```jsx
import { WhenVisible } from '@inertiajs/react'

export default () => (
  <WhenVisible data="permissions" fallback={<div>Loading...</div>}>
    <PermissionsChildComponent />
  </WhenVisible>
)
```

== Svelte 4

```svelte
<script>
  import { WhenVisible } from '@inertiajs/svelte'
  export let permissions
</script>

<WhenVisible data="permissions">
  <svelte:fragment slot="fallback">
    <div>Loading...</div>
  </svelte:fragment>

  {#each permissions as permission}
    <!-- ... -->
  {/each}
</WhenVisible>
```

== Svelte 5

```svelte
<script>
  import { WhenVisible } from '@inertiajs/svelte'

  let { permissions } = $props()
</script>

<WhenVisible data="permissions">
  {#snippet fallback()}
    <div>Loading...</div>
  {/snippet}

  {#each permissions as permission}
    <!-- ... -->
  {/each}
</WhenVisible>
```

:::

If you'd like to load multiple props when an element becomes visible, you can provide an array to the `data` prop.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { WhenVisible } from '@inertiajs/vue3'
</script>

<template>
  <WhenVisible :data="['teams', 'users']">
    <template #fallback>
      <div>Loading...</div>
    </template>
    <!-- Props are now loaded -->
  </WhenVisible>
</template>
```

== React

```jsx
import { WhenVisible } from '@inertiajs/react'

export default () => (
  <WhenVisible data={['teams', 'users']} fallback={<div>Loading...</div>}>
    <ChildComponent />
  </WhenVisible>
)
```

== Svelte 4

```svelte
<script>
  import { WhenVisible } from '@inertiajs/svelte'

  export let teams
  export let users
</script>

<WhenVisible data={['teams', 'users']}>
  <svelte:fragment slot="fallback">
    <div>Loading...</div>
  </svelte:fragment>

  <!-- Props are now loaded -->
</WhenVisible>
```

== Svelte 5

```svelte
<script>
  import { WhenVisible } from '@inertiajs/svelte'

  let { teams, users } = $props()
</script>

<WhenVisible data={['teams', 'users']}>
  {#snippet fallback()}
    <div>Loading...</div>
  {/snippet}

  <!-- Props are now loaded -->
</WhenVisible>
```

:::

## Loading before visible

If you'd like to start loading data before the element is visible, you can provide a value to the `buffer` prop. The buffer value is a number that represents the number of pixels before the element is visible.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { WhenVisible } from '@inertiajs/vue3'
</script>

<template>
  <WhenVisible data="permissions" :buffer="500">
    <template #fallback>
      <div>Loading...</div>
    </template>

    <div v-for="permission in permissions">
      <!-- ... -->
    </div>
  </WhenVisible>
</template>
```

== React

```jsx
import { WhenVisible } from '@inertiajs/react'

export default () => (
  <WhenVisible data="permissions" buffer={500} fallback={<div>Loading...</div>}>
    <PermissionsChildComponent />
  </WhenVisible>
)
```

== Svelte 4

```svelte
<script>
  import { WhenVisible } from '@inertiajs/svelte'

  export let permissions
</script>

<WhenVisible data="permissions" buffer={500}>
  <svelte:fragment slot="fallback">
    <div>Loading...</div>
  </svelte:fragment>

  {#each permissions as permission}
    <!-- ... -->
  {/each}
</WhenVisible>
```

== Svelte 5

```svelte
<script>
  import { WhenVisible } from '@inertiajs/svelte'

  let { permissions } = $props()
</script>

<WhenVisible data="permissions" buffer={500}>
  {#snippet fallback()}
    <div>Loading...</div>
  {/snippet}

  {#each permissions as permission}
    <!-- ... -->
  {/each}
</WhenVisible>
```

:::

In the above example, the data will start loading 500 pixels before the element is visible.

By default, the `WhenVisible` component wraps the fallback template in a `div` element so it can ensure the element is visible in the viewport. If you want to customize the wrapper element, you can provide the `as` prop.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { WhenVisible } from '@inertiajs/vue3'
</script>

<template>
  <WhenVisible data="products" as="span">
    <!-- ... -->
  </WhenVisible>
</template>
```

== React

```jsx
import { WhenVisible } from '@inertiajs/react'

export default () => (
  <WhenVisible data="products" as="span">
    <ProductsChildComponent />
  </WhenVisible>
)
```

== Svelte 4

```svelte
<script>
  import { WhenVisible } from '@inertiajs/svelte'

  export let products
</script>

<WhenVisible data="products" as="span">
  <!-- ... -->
</WhenVisible>
```

== Svelte 5

```svelte
<script>
  import { WhenVisible } from '@inertiajs/svelte'

  let { products } = $props()
</script>

<WhenVisible data="products" as="span">
  <!-- ... -->
</WhenVisible>
```

:::

## Always trigger

By default, the `WhenVisible` component will only trigger once when the element becomes visible. If you want to always trigger the data loading when the element is visible, you can provide the `always` prop.

This is useful when you want to load data every time the element becomes visible, such as when the element is at the end of an infinite scroll list and you want to load more data.

Note that if the data loading request is already in flight, the component will wait until it is finished to start the next request if the element is still visible in the viewport.

:::tabs key:frameworks
== Vue

```vue
<script setup>
import { WhenVisible } from '@inertiajs/vue3'
</script>

<template>
  <WhenVisible data="products" always>
    <!-- ... -->
  </WhenVisible>
</template>
```

== React

```jsx
import { WhenVisible } from '@inertiajs/react'

export default () => (
  <WhenVisible data="products" always>
    <ProductsChildComponent />
  </WhenVisible>
)
```

== Svelte 4

```svelte
<script>
  import { WhenVisible } from '@inertiajs/svelte'

  export let products
</script>

<WhenVisible data="products" always>
  <!-- ... -->
</WhenVisible>
```

== Svelte 5

```svelte
<script>
  import { WhenVisible } from '@inertiajs/svelte'

  let { products } = $props()
</script>

<WhenVisible data="products" always>
  <!-- ... -->
</WhenVisible>
```

:::
