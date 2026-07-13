# Code Splitting

By default, Inertia 3.x lazy-loads page components, splitting each page into its own bundle that is loaded on demand. This reduces the initial JavaScript bundle size but requires additional requests when visiting new pages.

You may disable lazy loading to eagerly bundle all pages into a single file. Eager loading eliminates per-page requests but increases the initial bundle size.

## Vite Plugin

@available_since core=3.0.0

The `lazy` option in the `pages` shorthand controls how page components are loaded. It defaults to `true`.

```js
createInertiaApp({
  pages: {
    lazy: false, // Bundle all pages into a single file
  },
  // ...
})
```

## Manual Vite

You may configure code splitting manually using Vite's `import.meta.glob()` function when not using the Inertia Vite plugin. Pass `{ eager: true }` to bundle all pages, or omit it to lazy-load them.

:::tabs key:frameworks

== Vue

```js
createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.vue') // [!code --:2]
    return pages[`../pages/${name}.vue`]()
    const pages = import.meta.glob('../pages/**/*.vue', { eager: true }) // [!code ++:2]
    return pages[`../pages/${name}.vue`]
  },
})
```

== React

```js
createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.jsx') // [!code --:2]
    return pages[`../pages/${name}.jsx`]()
    const pages = import.meta.glob('../pages/**/*.jsx', { eager: true }) // [!code ++:2]
    return pages[`../pages/${name}.jsx`]
  },
})
```

== Svelte

```js
createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.svelte') // [!code --:2]
    return pages[`../pages/${name}.svelte`]()
    const pages = import.meta.glob('../pages/**/*.svelte', { eager: true }) // [!code ++:2]
    return pages[`../pages/${name}.svelte`]
  },
})
```

:::

## Using Webpacker/Shakapacker

To use code splitting with Webpack, you will first need to enable [dynamic imports](https://github.com/tc39/proposal-dynamic-import) via a Babel plugin. Let's install it now.

```bash
npm install @babel/plugin-syntax-dynamic-import
```

Next, create a `.babelrc` file in your project with the following configuration:

```json
{
  "plugins": ["@babel/plugin-syntax-dynamic-import"]
}
```

Finally, update the `resolve` callback in your app's initialization code to use `import` instead of `require`.

:::tabs key:frameworks

== Vue

```js
resolve: name => require(`../pages/${name}`), // [!code --]
resolve: name => import(`../pages/${name}`), // [!code ++]
```

== React

```js
resolve: name => require(`../pages/${name}`), // [!code --]
resolve: name => import(`../pages/${name}`), // [!code ++]
```

== Svelte

```js
resolve: name => require(`../pages/${name}.svelte`), // [!code --]
resolve: name => import(`../pages/${name}.svelte`), // [!code ++]
```

:::

You should also consider using cache busting to force browsers to load the latest version of your assets. To accomplish this, add the following configuration to your webpack configuration file.

```js
output: {
    chunkFilename: 'js/[name].js?id=[chunkhash]',
}
```
