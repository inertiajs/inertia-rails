# Code splitting

Code splitting breaks apart the various pages of your application into smaller bundles, which are then loaded on demand when visiting new pages. This can significantly reduce the size of the initial JavaScript bundle loaded by the browser, improving the time to first render.

While code splitting is helpful for very large projects, it does require extra requests when visiting new pages. Generally speaking, if you're able to use a single bundle, your app is going to feel snappier.

To enable code splitting, you will need to tweak the `resolve` callback in your `createInertiaApp()` configuration, and how you do this is different depending on which bundler you're using.

## Using Vite

Vite enables code splitting (or lazy-loading as they call it) by default when using their `import.meta.glob()` function, so simply omit the `{ eager: true }` option, or set it to false, to disable eager loading.

:::tabs key:frameworks
== Vue

```js
// frontend/entrypoints/inertia.js
createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.vue', { eager: true }) // [!code --]
    return pages[`../pages/${name}.vue`] // [!code --]
    const pages = import.meta.glob('../pages/**/*.vue') // [!code ++]
    return pages[`../pages/${name}.vue`]() // [!code ++]
  },
  //...
})
```

== React

```js
// frontend/entrypoints/inertia.js
createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.jsx', { eager: true }) // [!code --]
    return pages[`../pages/${name}.jsx`] // [!code --]
    const pages = import.meta.glob('../pages/**/*.jsx') // [!code ++]
    return pages[`../pages/${name}.jsx`]() // [!code ++]
  },
  //...
})
```

== Svelte 4|Svelte 5

```js
// frontend/entrypoints/inertia.js
createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.svelte', { eager: true }) // [!code --]
    return pages[`../pages/${name}.svelte`] // [!code --]
    const pages = import.meta.glob('../pages/**/*.svelte') // [!code ++]
    return pages[`../pages/${name}.svelte`]() // [!code ++]
  },
  //...
})
```

:::

## Using Webpacker/Shakapacker

> [!WARNING]
> We recommend using [Vite Ruby](https://vite-ruby.netlify.app) for new projects.

To use code splitting with Webpack, you will first need to enable [dynamic imports](https://github.com/tc39/proposal-dynamic-import) via a Babel plugin. Let's install it now.

```shell
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
// javascript/packs/inertia.js
createInertiaApp({
  resolve: (name) => require(`../pages/${name}`), // [!code ii]
  resolve: (name) => import(`../pages/${name}`), // [!code ++]
  //...
})
```

== React

```js
// javascript/packs/inertia.js
createInertiaApp({
  resolve: (name) => require(`../pages/${name}`), // [!code ii]
  resolve: (name) => import(`../pages/${name}`), // [!code ++]
  //...
})
```

== Svelte 4|Svelte 5

```js
// javascript/packs/inertia.js
createInertiaApp({
  resolve: (name) => require(`../pages/${name}.svelte`), // [!code ii]
  resolve: (name) => import(`../pages/${name}.svelte`), // [!code ++]
  //...
})
```

:::

You should also consider using cache busting to force browsers to load the latest version of your assets. To accomplish this, add the following configuration to your webpack configuration file.

```js
// webpack.config.js
module.exports = {
  //...
  output: {
    //...
    chunkFilename: 'js/[name].js?id=[chunkhash]',
  },
}
```
