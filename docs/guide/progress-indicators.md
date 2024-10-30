# Progress indicators

Since Inertia requests are made via XHR, there would typically not be a browser loading indicator when navigating from one page to another. To solve this, Inertia displays a progress indicator at the top of the page whenever you make an Inertia visit. However, [asynchronous requests](#visit-options) do not show the progress indicator unless explicitly configured.

Of course, if you prefer, you can disable Inertia's default loading indicator and provide your own custom implementation. We'll discuss both approaches below.

## Default

Inertia's default progress indicator is a light-weight wrapper around the [NProgress](https://ricostacruz.com/nprogress/) library. You can customize it via the `progress` property of the `createInertiaApp()` function.

```js
createInertiaApp({
  progress: {
    // The delay after which the progress bar will appear, in milliseconds...
    delay: 250,

    // The color of the progress bar...
    color: '#29d',

    // Whether to include the default NProgress styles...
    includeCSS: true,

    // Whether the NProgress spinner will be shown...
    showSpinner: false,
  },
  // ...
})
```

You can disable Inertia's default loading indicator by setting the `progress` property to `false`.

```js
createInertiaApp({
  progress: false,
  // ...
})
```

## Custom

It's also possible to setup your own custom page loading indicators using [Inertia events](/guide/events.md). Let's explore how to do this using the [NProgress](https://ricostacruz.com/nprogress/) library as an example.

First, disable Inertia's default loading indicator.

```js
createInertiaApp({
  progress: false,
  // ...
})
```

Next, install the NProgress library.

```shell
npm install nprogress
```

After installation, you'll need to add the [NProgress styles](https://github.com/rstacruz/nprogress/blob/master/nprogress.css) to your project. You can do this using a CDN hosted copy of the styles.

```html
<link
  rel="stylesheet"
  href="https://cdnjs.cloudflare.com/ajax/libs/nprogress/0.2.0/nprogress.min.css"
/>
```

Next, import both `NProgress` and the Inertia `router` into your application.

:::tabs key:frameworks
== Vue

```js
import NProgress from 'nprogress'
import { router } from '@inertiajs/vue3'
```

== React

```js
import NProgress from 'nprogress'
import { router } from '@inertiajs/react'
```

== Svelte 4|Svelte 5

```js
import NProgress from 'nprogress'
import { router } from '@inertiajs/svelte'
```

:::

Next, let's add a `start` event listener. We'll use this listener to show the progress bar when a new Inertia visit begins.

```js
router.on('start', () => NProgress.start())
```

Then, let's add a `finish` event listener to hide the progress bar when the page visit finishes.

```js
router.on('finish', () => NProgress.done())
```

That's it! Now, as you navigate from one page to another, the progress bar will be added and removed from the page.

### Handling cancelled visits

While this custom progress implementation works great for page visits that finish properly, it would be nice to handle cancelled visits as well. First, for interrupted visits (those that get cancelled as a result of a new visit), the progress bar should simply be reset back to the start position. Second, for manually cancelled visits, the progress bar should be immediately removed from the page.

We can accomplish this by inspecting the `event.detail.visit` object that's provided to the finish event.

```js
router.on('finish', (event) => {
  if (event.detail.visit.completed) {
    NProgress.done()
  } else if (event.detail.visit.interrupted) {
    NProgress.set(0)
  } else if (event.detail.visit.cancelled) {
    NProgress.done()
    NProgress.remove()
  }
})
```

### File upload progress

Let's take this a step further. When files are being uploaded, it would be great to update the loading indicator to reflect the upload progress. This can be done using the `progress` event.

```js
router.on('progress', (event) => {
  if (event.detail.progress.percentage) {
    NProgress.set((event.detail.progress.percentage / 100) * 0.9)
  }
})
```

Now, instead of the progress bar "trickling" while the files are being uploaded, it will actually update it's position based on the progress of the request. We limit the progress here to 90%, since we still need to wait for a response from the server.

### Loading indicator delay

The last thing we're going to implement is a loading indicator delay. It's often preferable to delay showing the loading indicator until a request has taken longer than 250-500 milliseconds. This prevents the loading indicator from appearing constantly on quick page visits, which can be visually distracting.

To implement the delay behavior, we'll use the `setTimeout` and `clearTimeout` functions. Let's start by defining a variable to keep track of the timeout.

```js
let timeout = null
```

Next, let's update the `start` event listener to start a new timeout that will show the progress bar after 250 milliseconds.

```js
router.on('start', () => {
  timeout = setTimeout(() => NProgress.start(), 250)
})
```

Next, we'll update the `finish` event listener to clear any existing timeouts in the event that the page visit finishes before the timeout does.

```js
router.on('finish', (event) => {
  clearTimeout(timeout)
  // ...
})
```

In the `finish` event listener, we need to determine if the progress bar has actually started displaying progress, otherwise we'll inadvertently cause it to show before the timeout has finished.

```js
router.on('finish', (event) => {
  clearTimeout(timeout)
  if (!NProgress.isStarted()) {
    return
  }
  // ...
})
```

And, finally, we need to do the same check in the `progress` event listener.

```js
router.on('progress', event => {
  if (!NProgress.isStarted()) {
    return
  }
  // ...
}
```

That's it, you now have a beautiful custom page loading indicator!

### Complete example

For convenience, here is the full source code of the final version of our custom loading indicator.

:::tabs key:frameworks
== Vue

```js
import NProgress from 'nprogress'
import { router } from '@inertiajs/vue3'

let timeout = null

router.on('start', () => {
  timeout = setTimeout(() => NProgress.start(), 250)
})

router.on('progress', (event) => {
  if (NProgress.isStarted() && event.detail.progress.percentage) {
    NProgress.set((event.detail.progress.percentage / 100) * 0.9)
  }
})

router.on('finish', (event) => {
  clearTimeout(timeout)
  if (!NProgress.isStarted()) {
    return
  } else if (event.detail.visit.completed) {
    NProgress.done()
  } else if (event.detail.visit.interrupted) {
    NProgress.set(0)
  } else if (event.detail.visit.cancelled) {
    NProgress.done()
    NProgress.remove()
  }
})
```

== React

```js
import NProgress from 'nprogress'
import { router } from '@inertiajs/react'

let timeout = null

router.on('start', () => {
  timeout = setTimeout(() => NProgress.start(), 250)
})

router.on('progress', (event) => {
  if (NProgress.isStarted() && event.detail.progress.percentage) {
    NProgress.set((event.detail.progress.percentage / 100) * 0.9)
  }
})

router.on('finish', (event) => {
  clearTimeout(timeout)
  if (!NProgress.isStarted()) {
    return
  } else if (event.detail.visit.completed) {
    NProgress.done()
  } else if (event.detail.visit.interrupted) {
    NProgress.set(0)
  } else if (event.detail.visit.cancelled) {
    NProgress.done()
    NProgress.remove()
  }
})
```

== Svelte 4|Svelte 5

```js
import NProgress from 'nprogress'
import { router } from '@inertiajs/svelte'

let timeout = null

router.on('start', () => {
  timeout = setTimeout(() => NProgress.start(), 250)
})

router.on('progress', (event) => {
  if (NProgress.isStarted() && event.detail.progress.percentage) {
    NProgress.set((event.detail.progress.percentage / 100) * 0.9)
  }
})

router.on('finish', (event) => {
  clearTimeout(timeout)
  if (!NProgress.isStarted()) {
    return
  } else if (event.detail.visit.completed) {
    NProgress.done()
  } else if (event.detail.visit.interrupted) {
    NProgress.set(0)
  } else if (event.detail.visit.cancelled) {
    NProgress.done()
    NProgress.remove()
  }
})
```

:::

## Visit Options

In addition to these configurations, Inertia.js provides two visit options to control the loading indicator on a per-request basis: `showProgress` and `async`. These options offer greater control over how Inertia.js handles asynchronous requests and manages progress indicators.

### `showProgress`

The `showProgress` option provides fine-grained control over the visibility of the loading indicator during requests.

```js
router.get('/settings', {}, { showProgress: false })
```

### `async`

The `async` option allows you to perform asynchronous requests without displaying the default progress indicator. It can be used in combination with the `showProgress` option.

```js
// Disable the progress indicator
router.get('/settings', {}, { async: true })
// Enable the progress indicator with async requests
router.get('/settings', {}, { async: true, showProgress: true })
```
