# Server-Side Rendering (SSR)

Server-side rendering pre-renders your JavaScript pages on the server, allowing your visitors to receive fully rendered HTML when they visit your application. Since fully rendered HTML is served by your application, it's also easier for search engines to index your site.

Server-side rendering uses Node.js to render your pages in a background process; therefore, Node must be available on your server for server-side rendering to function properly. Inertia's SSR server requires Node.js 22 or higher.

## Vite Plugin Setup

@available_since rails=3.19.0 core=3.0.0

The recommended way to configure SSR is with the `@inertiajs/vite` plugin. This approach handles SSR configuration automatically, including development mode SSR without a separate Node.js server.

### 1. Install the Vite plugin

```bash
npm install @inertiajs/vite
```

### 2. Configure Vite

Add the Inertia plugin to your `vite.config.js` file, and configure the entry point.

```js
// vite.config.js
import inertia from '@inertiajs/vite'

export default defineConfig({
  plugins: [
    // ...
    inertia({
      ssr: {
        entry: 'entrypoints/inertia.js',
      },
    }),
  ],
})
```

> [!NOTE]
> `ssr.entry` is resolved against the Vite root. With `vite_rails` the root is your source directory, so `entrypoints/inertia.js` works. With [`rails_vite`](https://github.com/skryukov/rails_vite) the root is the project root — use `app/javascript/entrypoints/inertia.js`. A wrong path logs a one-line warning and silently falls back to client-side rendering.
>
> `@inertiajs/vite` is ESM-only: if Vite fails to load your config with "this package is ESM only", add `"type": "module"` to your `package.json`.

You may also configure SSR options explicitly.

```js
// vite.config.js
inertia({
  ssr: {
    entry: 'ssr/ssr.js',
    port: 13714,
    cluster: true,
  },
})
```

You may pass `false` to opt out of the plugin's automatic SSR handling, for example if you prefer to [configure SSR manually](#manual-setup) or [disable SSR entirely](#disabling-ssr).

```js
// vite.config.js
inertia({
  ssr: false,
})
```

### 3. Configure the SSR build

How the SSR bundle gets built in production depends on your Vite integration gem.

With `vite_rails` (Vite Ruby), production builds run through `rails assets:precompile`, and `vite-plugin-ruby` resolves the SSR entry point on its own. Point `ssrEntrypoint` at your client entry point — the Inertia plugin adapts it for the server — and enable the SSR build in `config/vite.json`:

```json
// config/vite.json
"all": {
  "ssrEntrypoint": "~/entrypoints/inertia.js"
},
"production": {
  "ssrBuildEnabled": true
}
```

With this in place, `rails assets:precompile` builds both bundles. Without `ssrEntrypoint`, `vite build --ssr` fails with `No SSR entrypoint available`. Skip that line only if you use a dedicated [custom SSR entry point](#custom-ssr-entry-point) at `~/ssr/ssr.js`, which Vite Ruby finds on its own.

With [`rails_vite`](https://github.com/skryukov/rails_vite), no extra Vite configuration is needed — the Inertia plugin supplies the SSR entry. However, the gem's `assets:precompile` hook builds only the client bundle (it invokes `vite build` directly and never runs your `package.json` scripts). Enhance the task so precompilation builds the SSR bundle too:

```ruby
# lib/tasks/vite_ssr.rake
namespace :vite do
  desc "Build the Vite SSR bundle"
  task :build_ssr do
    command = "#{RailsVite::Tasks.build_command} --ssr"
    system(command) || raise("vite:build_ssr failed")
  end
end

Rake::Task["vite:build"].enhance do
  Rake::Task["vite:build_ssr"].invoke
end
```

For builds outside `assets:precompile` (CI checks, manual builds), a `package.json` script with `vite build && vite build --ssr` works as well.

### 4. Enable SSR in the adapter

Turn SSR on in the Inertia Rails configuration:

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.ssr_enabled = true
end
```

In development, the plugin's dev server endpoint handles rendering. In production, the adapter sends render requests to the SSR server running your built bundle.

> [!WARNING]
> If your SSR server uses a non-default port (the default is 13714), set `config.ssr_url` to match — but only outside development. An explicit `ssr_url` takes precedence over the dev server detection, so setting it unconditionally silently disables development-mode SSR:
>
> ```ruby
> config.ssr_url = "http://localhost:13721" if Rails.env.production?
> ```

### Development Mode

The Vite plugin handles SSR automatically during development. There is no need to build your SSR bundle or start a separate Node.js server. Simply run your dev servers as usual:

```bash
bin/dev
```

The Vite plugin exposes a server endpoint that Rails uses for rendering, complete with HMR support.

> [!NOTE]
> The `vite build --ssr`, `bin/vite ssr`, etc. commands are for [production](#production) only. You should not run them during development.

### Production

For production, `rails assets:precompile` builds both bundles. Where the SSR bundle lands and how to start the server depends on your Vite integration:

- `vite_rails`: the bundle is written to `public/vite-ssr/ssr.js`; run it with `bin/vite ssr`.
- `rails_vite`: the bundle is written to `ssr/`, named after your entry point (for example `ssr/inertia.js`); run it with `node ssr/inertia.js`.

The recommended way to run the server in production is the [Puma plugin](#puma-plugin), which locates the bundle for either integration and manages the SSR process for you.

### Custom SSR Entry Point

The Vite plugin reuses your `inertia.js` entry point for both browser and SSR rendering by default, so no separate file is needed. The client adapter detects the `data-server-rendered` attribute (emitted by the SSR process) to decide whether to hydrate or mount, and the `setup` and `resolve` callbacks are optional.

Most app customizations, such as registering plugins or wrapping with providers, may be handled using the [`withApp` callback](/guide/client-side-setup#customizing-the-app) in your main entry point. A separate SSR entry point is only needed when you require completely different setup logic for the server.

You may create a separate `app/frontend/ssr/ssr.js` file for this purpose.

:::tabs key:frameworks

== Vue

```js
import { createInertiaApp } from '@inertiajs/vue3'
import createServer from '@inertiajs/vue3/server'
import { renderToString } from '@vue/server-renderer'
import { createSSRApp, h } from 'vue'

createServer((page) =>
  createInertiaApp({
    page,
    render: renderToString,
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.vue')
      return pages[`../pages/${name}.vue`]()
    },
    setup({ App, props, plugin }) {
      return createSSRApp({
        render: () => h(App, props),
      }).use(plugin)
    },
  }),
)
```

== React

```jsx
import { createInertiaApp } from '@inertiajs/react'
import createServer from '@inertiajs/react/server'
import ReactDOMServer from 'react-dom/server'

createServer((page) =>
  createInertiaApp({
    page,
    render: ReactDOMServer.renderToString,
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.jsx')
      return pages[`../pages/${name}.jsx`]()
    },
    setup: ({ App, props }) => <App {...props} />,
  }),
)
```

== Svelte

```js
import { createInertiaApp } from '@inertiajs/svelte'
import createServer from '@inertiajs/svelte/server'
import { render } from 'svelte/server'

createServer((page) =>
  createInertiaApp({
    page,
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.svelte')
      return pages[`../pages/${name}.svelte`]()
    },
    setup({ App, props }) {
      return render(App, { props })
    },
  }),
)
```

:::

Be sure to add anything that's missing from your `inertia.js` file that makes sense to run in SSR mode, such as plugins or custom mixins.

### Host

@available_since core=3.1.0

By default, the SSR server binds to `0.0.0.0`, making it accessible on all network interfaces. You may restrict it to a specific interface using the `host` option.

```js
// vite.config.js
inertia({
  ssr: {
    host: '127.0.0.1',
  },
})
```

## Manual Setup

If you prefer not to use the Vite plugin, you may configure SSR manually.

### 1. Create an SSR entry point

Create an SSR entry point file within your Rails project.

:::tabs key:frameworks
== Vue

```bash
touch app/frontend/ssr/ssr.js
```

== React

```bash
touch app/frontend/ssr/ssr.jsx
```

== Svelte

```bash
touch app/frontend/ssr/ssr.js
```

:::

This file will look similar to your app entry point, but it runs in Node.js instead of the browser. Here's a complete example.

:::tabs key:frameworks

== Vue

```js
import { createInertiaApp } from '@inertiajs/vue3'
import createServer from '@inertiajs/vue3/server'
import { renderToString } from '@vue/server-renderer'
import { createSSRApp, h } from 'vue'

createServer((page) =>
  createInertiaApp({
    page,
    render: renderToString,
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.vue')
      return pages[`../pages/${name}.vue`]()
    },
    setup({ App, props, plugin }) {
      return createSSRApp({
        render: () => h(App, props),
      }).use(plugin)
    },
  }),
)
```

== React

```jsx
import { createInertiaApp } from '@inertiajs/react'
import createServer from '@inertiajs/react/server'
import ReactDOMServer from 'react-dom/server'

createServer((page) =>
  createInertiaApp({
    page,
    render: ReactDOMServer.renderToString,
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.jsx')
      return pages[`../pages/${name}.jsx`]()
    },
    setup: ({ App, props }) => <App {...props} />,
  }),
)
```

== Svelte

```js
import { createInertiaApp } from '@inertiajs/svelte'
import createServer from '@inertiajs/svelte/server'
import { render } from 'svelte/server'

createServer((page) =>
  createInertiaApp({
    page,
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.svelte')
      return pages[`../pages/${name}.svelte`]()
    },
    setup({ App, props }) {
      return render(App, { props })
    },
  }),
)
```

:::

> [!NOTE]
> The second argument to `createServer` accepts `port`, `host`, and `cluster` options (the default port is 13714). If you pick a custom port, set `config.ssr_url` to match — in production only, since an explicit `ssr_url` overrides development-mode SSR detection.
>
> If your client entry point uses the `pages:` shorthand added by the installer, it is compiled by the `@inertiajs/vite` plugin. Without the plugin, rewrite the client entry using the explicit `resolve`/`setup` form.

### 2. Configure Vite

Next, we need to update our Vite configuration to build our new `ssr.js` file. With `vite_rails`, add a `ssrBuildEnabled` property to the Ruby Vite plugin configuration in the `config/vite.json` file — the default `ssrEntrypoint` glob finds your `~/ssr/ssr.js` file automatically:

```json
"production": {
  "ssrBuildEnabled": true
}
```

With [`rails_vite`](https://github.com/skryukov/rails_vite), there is no `config/vite.json` — create the entry under `app/javascript/ssr/` instead, point the plugin's `ssr` option at it in `vite.config.js` (`rails({ ssr: 'ssr/ssr.js' })`, resolved from your source directory), and add the [rake enhancement](#_3-configure-the-ssr-build) so `assets:precompile` builds it.

### 3. Enable SSR in the Inertia's Rails adapter

Update the Inertia Rails adapter config to turn SSR on.

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.ssr_enabled = ViteRuby.config.ssr_build_enabled
end
```

With `rails_vite` there is no `ViteRuby` constant — use `config.ssr_enabled = true` instead.

### Clustering

By default, the SSR server runs on a single thread. You may enable clustering to start multiple Node servers on the same port, with requests handled by each thread in a round-robin fashion.

```js
// vite.config.js
inertia({
  ssr: {
    cluster: true,
  },
})
```

When using a [custom SSR entry point](#custom-ssr-entry-point) or [manual setup](#manual-setup), you may pass the `cluster` option to `createServer` instead.

@available_since core=2.0.7

:::tabs key:frameworks

== Vue

```js
createServer(
  (page) =>
    createInertiaApp({
      // ...
    }),
  { cluster: true },
)
```

== React

```jsx
createServer(
  (page) =>
    createInertiaApp({
      // ...
    }),
  { cluster: true },
)
```

== Svelte

```js
createServer(
  (page) =>
    createInertiaApp({
      // ...
    }),
  { cluster: true },
)
```

:::

### Host

@available_since core=3.1.0

By default, the SSR server binds to `0.0.0.0`, making it accessible on all network interfaces. You may pass the `host` option to `createServer` to restrict it to a specific interface.

:::tabs key:frameworks

== Vue

```js
createServer(
  (page) =>
    createInertiaApp({
      // ...
    }),
  { host: '127.0.0.1' },
)
```

== React

```jsx
createServer(
  (page) =>
    createInertiaApp({
      // ...
    }),
  { host: '127.0.0.1' },
)
```

== Svelte

```js
createServer(
  (page) =>
    createInertiaApp({
      // ...
    }),
  { host: '127.0.0.1' },
)
```

:::

## Running the SSR Server

> [!NOTE]
> The SSR server is only required in production. During development, the [Vite plugin](#development-mode) handles SSR automatically.

### Puma Plugin

@available_since rails=3.20.0

The recommended way to run the SSR server in production is with the built-in Puma plugin. Add the plugin to your Puma configuration:

```ruby
# config/puma.rb
plugin :inertia_ssr
```

The plugin automatically starts and stops the SSR Node.js process alongside Puma. It handles health checks, automatic restarts on crashes, and graceful shutdown. No separate process management (systemd, Procfile, etc.) is needed.

The plugin is a no-op when `ssr_enabled` is `false` or the SSR bundle is not found, so it is safe to add unconditionally.

#### Bundle Resolution

The plugin locates the SSR bundle using the following rules, in order:

1. **Explicit config** — `config.ssr_bundle` (a path or an array of paths; the first existing file wins).
2. **ViteRuby output** — if ViteRuby is loaded, it globs `<ssr_output_dir>/*.js`.
3. **`ssr/` directory** — globs `ssr/*.js` in the project root (matches `rails-vite-plugin`'s default `ssrOutDir`).
4. **Legacy fallback** — checks `public/assets-ssr/*.js`.

If none of the above finds a file, the plugin logs nothing and stays idle.

#### Runtime Detection

The JavaScript runtime is auto-detected from your lockfile (`bun.lockb` → Bun, `deno.lock` → Deno, otherwise Node.js). To override:

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.ssr_runtime = "bun"
end
```

### Manual

If you are not using Puma, or prefer to manage the SSR process yourself, start the SSR server manually:

```bash
bin/vite ssr
```

With the server running, you should be able to access your app within the browser with server-side rendering enabled. In fact, you should be able to disable JavaScript entirely and still navigate around your application.

## Client-Side Hydration

You should also update your `inertia.js` file to use hydration instead of normal rendering. This allows <Vue>Vue</Vue><React>React</React><Svelte>Svelte</Svelte> to pick up the server-rendered HTML and make it interactive without re-rendering it.

:::tabs key:frameworks

== Vue

```js
import { createApp, h } from 'vue' // [!code --]
import { createSSRApp, h } from 'vue' // [!code ++]

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.vue')
    return pages[`../pages/${name}.vue`]()
  },
  setup({ el, App, props, plugin }) {
    createApp({ render: () => h(App, props) }) // [!code --]
    createSSRApp({ render: () => h(App, props) }) // [!code ++]
      .use(plugin)
      .mount(el)
  },
})
```

== React

```js
import { createRoot } from 'react-dom/client' // [!code --]
import { hydrateRoot } from 'react-dom/client' // [!code ++]

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.jsx')
    return pages[`../pages/${name}.jsx`]()
  },
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />) // [!code --]
    hydrateRoot(el, <App {...props} />) // [!code ++]
  },
})
```

== Svelte

```js
import { mount } from 'svelte' // [!code --]
import { hydrate, mount } from 'svelte' // [!code ++]

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.svelte')
    return pages[`../pages/${name}.svelte`]()
  },
  setup({ el, App, props }) {
    mount(App, { target: el, props }) // [!code --]
    if (el.dataset.serverRendered === 'true') {
      // [!code ++:5]
      hydrate(App, { target: el, props })
    } else {
      mount(App, { target: el, props })
    }
  },
})
```

:::

## Error Handling

When SSR rendering fails, Inertia gracefully falls back to client-side rendering. The Vite plugin logs detailed error information to the console, including the component name, request URL, source location, and a tailored hint to help you resolve the issue.

Common SSR errors are automatically classified. Browser API errors (such as referencing `window` or `document` in server-rendered code) include guidance on moving the code to a lifecycle hook. Component resolution errors suggest checking file paths and casing.

The Rails adapter automatically logs SSR failures to `Rails.logger` at the `error` level. To customize error handling, set the `on_ssr_error` option in your `config/initializers/inertia_rails.rb` file.

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.on_ssr_error = ->(error, page) do
    Rails.logger.warn("SSR failed for #{page[:component]}: #{error.message}")
    Sentry.capture_exception(error) # or any error tracker
  end
end
```

The callback receives an `InertiaRails::SSRError` and the page hash, giving you access to the component name, props, and URL that failed.

### Raising on Error

For CI or E2E testing, you may prefer SSR failures to raise an exception instead of falling back silently. Set the `ssr_raise_on_error` option in your initializer.

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.ssr_raise_on_error = true
end
```

## SSR Response Caching

@available_since rails=3.19.0

SSR rendering sends a request to the Node.js server for every page load. You can cache these responses to avoid redundant renders when the same page data is served repeatedly.

### Enabling SSR Caching

Set `ssr_cache` in your initializer:

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.ssr_cache = true
end
```

When enabled, the SSR response is cached using an MD5 digest of the page JSON as the cache key. Identical page data produces the same key, so the Node.js server is only called once per unique page.

### Cache Options

Pass a hash to control cache behavior:

```ruby
InertiaRails.configure do |config|
  config.ssr_cache = { expires_in: 1.hour }
end
```

### Dynamic Configuration

Use a lambda for per-request control. The lambda is evaluated in the controller context:

```ruby
InertiaRails.configure do |config|
  config.ssr_cache = -> { { expires_in: action_name == 'index' ? 1.hour : 5.minutes } }
end
```

### Per-Render Override

Override the global setting on individual render calls:

```ruby
class PostsController < ApplicationController
  def show
    render inertia: 'Posts/Show',
      props: { post: @post.as_json },
      ssr_cache: false  # skip caching for this render
  end
end
```

### Development Mode

SSR caching is automatically disabled when the Vite dev server is running, since dev responses change frequently and should not be cached.

### Cache Store

SSR caching uses the same [`cache_store`](/guide/configuration#cache_store) as [cached props](/guide/cached-props). SSR cache keys are prefixed with `inertia_ssr/`.

## Disabling SSR

SSR has two layers: the **Vite plugin** serves SSR during development and builds the SSR bundle for production, while the **Rails adapter** dispatches rendering requests to the SSR server. To fully disable SSR, you should disable both.

```js
// vite.config.js
inertia({
  ssr: false,
})
```

```ruby
# config/initializers/inertia.rb
InertiaRails.configure do |config|
  config.ssr_enabled = false
end
```

## Excluding Controllers from SSR

Sometimes you may wish to skip server-side rendering for certain controllers while keeping SSR enabled for the rest of your application.

```ruby
class AdminController < ApplicationController
  inertia_config(ssr_enabled: false)
end
```

You can also use a lambda for conditional SSR, which is evaluated per-request in the controller context:

```ruby
class DashboardController < ApplicationController
  inertia_config(ssr_enabled: -> { !complex_client_only_page? })
end
```

## Deployment

When deploying your SSR enabled app to production, build both the client-side (`application.js`) and server-side bundles (`ssr.js`), and then run the SSR server as a background process — either via the [Puma plugin](#puma-plugin) or manually.

> [!NOTE]
> The Puma plugin expects Node.js (or your configured runtime) to be available in the same environment as Puma. For containerized deployments where the SSR server runs in a separate container, skip the plugin and point `ssr_url` to the SSR container instead.
