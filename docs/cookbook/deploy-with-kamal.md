# Deploy with Kamal

Rails ships with [Kamal](https://kamal-deploy.org/) preconfigured as the default deployment tool. A client-rendered Inertia Rails app deploys with a single config tweak — [updating the asset path](#update-the-asset-path). Enabling [SSR](/guide/server-side-rendering) adds one decision: where the SSR process runs. This guide covers both options — inside the web container via the built-in Puma plugin (recommended), and as a separate Kamal role.

> [!NOTE]
> This guide is based on Rails 8 and Kamal 2. It assumes SSR already works in development — see the [server-side rendering guide](/guide/server-side-rendering) for the initial setup.

> [!TIP]
> The official [starter kits](/guide/starter-kits) ship this whole arrangement out of the box — an SSR-ready Dockerfile with Node.js in the runtime image, the `noExternal` build configuration, and the Puma plugin.

## Update the asset path

During a deploy, Kamal bridges fingerprinted assets between the old and new versions of the app, so in-flight requests don't hit 404s. An Inertia Rails app serves fingerprinted files from two directories — `public/vite` (Vite Ruby) and `public/assets` (Propshaft, used by the default layout's stylesheet) — and Kamal supports only a single `asset_path`, so point it at their common parent:

```yml
# config/deploy.yml
asset_path: /rails/public/assets # [!code --]
asset_path: /rails/public # [!code ++]
```

Kamal merges the old and new directories without overwriting same-named files, so unfingerprinted files like error pages and `robots.txt` stay correct for each running version.

> [!NOTE]
> If your app keeps large static files in `public`, or gems write there at runtime (sitemap generators, upload folders), narrow the path to `/rails/public/vite` — at the cost of not bridging Propshaft assets during deploys.

This is the only Kamal-specific change a client-rendered Inertia app needs. One caveat: `assets:precompile` runs Vite inside `docker build`, so your Dockerfile must install Node.js in the `build` stage. If your app was generated without a JavaScript bundler, the default Dockerfile skips that — add the install block from [Make Node.js available at runtime](#make-node-js-available-at-runtime) (for a client-rendered app, the `build` stage is enough). If you don't use SSR, you can stop here.

## Build the SSR bundle during image build

Kamal packages your app as a Docker image, and `assets:precompile` runs inside `docker build`. By default, it only builds the client bundle — enable the SSR build for your Vite integration:

:::tabs key:vite

== vite_rails

Enable the SSR build in `config/vite.json` so precompilation produces both bundles:

```json
// config/vite.json
"all": {
  "ssrEntrypoint": "~/entrypoints/inertia.js"
},
"production": {
  "ssrBuildEnabled": true
}
```

The `ssrEntrypoint` line points Vite Ruby's SSR build at your client entry point (adjust the path to your entry file's actual name and extension — `.jsx`, `.ts`, or `.tsx`) — the [Inertia Vite plugin](/guide/server-side-rendering#vite-plugin-setup) adapts it for the server automatically. Without it, the SSR build fails with `No SSR entrypoint available`. Skip that line only if you use a dedicated `~/ssr/ssr.js` entry point ([manual setup](/guide/server-side-rendering#manual-setup)), which Vite Ruby finds on its own.

== rails_vite

There is no `config/vite.json` — add the [rake enhancement from the SSR guide](/guide/server-side-rendering#_3-configure-the-ssr-build) so `assets:precompile` builds the SSR bundle. In [Option B](#option-b-separate-ssr-container), start the SSR server with `node ssr/inertia.js` (the bundle is named after your entry point) rather than `bin/vite ssr`.

:::

Then make sure SSR is enabled in the adapter:

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.ssr_enabled = true
end
```

> [!NOTE]
> If you use the `config.ssr_enabled = ViteRuby.config.ssr_build_enabled` tie from the [manual SSR setup](/guide/server-side-rendering#manual-setup), keep it — it evaluates to `true` in production now that `ssrBuildEnabled` is set.

## Make Node.js available at runtime

The default Rails Dockerfile installs Node.js only in the throwaway `build` stage — or not at all, if your app was generated without a JavaScript bundler. The SSR server is a Node.js process, so the final image needs the `node` binary too.

Move the entire "Install JavaScript dependencies" block from the `build` stage into the `base` stage, keeping the versions and package manager commands your Dockerfile already uses. If your Dockerfile has no such block, add it to the `base` stage:

```dockerfile
# Dockerfile
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# ...

# Install JavaScript dependencies # [!code ++]
ARG NODE_VERSION=22.16.0 # [!code ++]
ENV PATH=/usr/local/node/bin:$PATH # [!code ++]
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \ # [!code ++]
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \ # [!code ++]
    rm -rf /tmp/node-build-master # [!code ++]

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install JavaScript dependencies # [!code --]
ARG NODE_VERSION=22.16.0 # [!code --]
ENV PATH=/usr/local/node/bin:$PATH # [!code --]
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \ # [!code --]
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \ # [!code --]
    rm -rf /tmp/node-build-master # [!code --]
```

By default, the SSR bundle imports its dependencies from `node_modules` at runtime, so removing the packages from the image would crash the SSR server at boot. Pages would still render through the client-side fallback, with every SSR failure logged to `Rails.logger` — wire up [`on_ssr_error`](/guide/server-side-rendering#error-handling) to surface such failures in your error tracker. To keep the runtime image slim, make the bundle self-contained first:

```js
// vite.config.js
export default defineConfig(({ command }) => ({
  ssr: {
    // Bundle dependencies into the SSR build. Only do this for production
    // builds: CJS-only packages (like React) must stay external in
    // development, or dev-mode SSR breaks.
    noExternal: command === 'build' ? true : undefined,
  },
  // ...
}))
```

With that in place, keep the `rm -rf node_modules` line at the end of the `build` stage — and if your Dockerfile doesn't have one, add it after the `assets:precompile` step; the runtime image then needs only the `node` binary:

```dockerfile
# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

RUN rm -rf node_modules # [!code ++]
```

If you'd rather not bundle dependencies into the SSR bundle, drop the `rm -rf node_modules` line instead, so the packages ship with the image.

> [!NOTE]
> If your app uses Bun, apply the same change to the Bun install block instead. The adapter [detects the runtime automatically](/guide/server-side-rendering#runtime-detection) from your lockfile.

## Run the SSR server

You can run the SSR server inside the web container with the Puma plugin, or as a separate container with its own Kamal role. The Puma plugin is simpler and fits most single-server setups, so start there.

### Option A: Puma plugin (recommended)

@available_since rails=3.20.0

Add the built-in Puma plugin to your Puma configuration:

```ruby
# config/puma.rb
plugin :inertia_ssr
```

The plugin starts the SSR process alongside Puma inside the same container, health-checks it, restarts it on crashes, and stops it on shutdown. It locates the SSR bundle automatically, so no `config/deploy.yml` changes are needed — the default `web` role runs everything. See the [Puma plugin documentation](/guide/server-side-rendering#puma-plugin) for details.

> [!NOTE]
> If a request arrives while the SSR process is still booting, Inertia Rails logs the error and falls back to client-side rendering for that request — the page still renders.

### Option B: separate SSR container

To scale SSR independently from the web server, run it as a dedicated Kamal role. The role reuses the same app image and starts the SSR server with `bin/vite ssr`:

```yml
# config/deploy.yml
servers:
  web:
    - 192.168.0.1
  ssr: # [!code ++]
    hosts: # [!code ++]
      - 192.168.0.1 # [!code ++]
    cmd: bin/vite ssr # [!code ++]
    options: # [!code ++]
      network-alias: inertia-ssr # [!code ++]

env:
  clear:
    INERTIA_SSR_URL: 'http://inertia-ssr:13714' # [!code ++]
```

Then point the adapter at the SSR container:

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.ssr_enabled = true
  config.ssr_url = ENV["INERTIA_SSR_URL"] if ENV["INERTIA_SSR_URL"] # [!code ++]
end
```

A few things to keep in mind with this setup:

- Don't add the Puma plugin — pointing `ssr_url` at the SSR container replaces it.
- The `network-alias` value must match the hostname in `INERTIA_SSR_URL`. Kamal connects all containers on a host to a shared Docker network, so the alias resolves from the web container.
- The SSR server binds to `0.0.0.0` by default, so it accepts connections from other containers. If you [restricted the host](/guide/server-side-rendering#host), remove that restriction for this setup.
- If the web and SSR roles run on different servers, the Docker network alias won't resolve across hosts — set `INERTIA_SSR_URL` to an address the web server can reach instead.

## Deploy

With the configuration in place, ship it:

```bash
kamal setup  # first deploy only: installs Docker and the proxy on the server
kamal deploy
```

Your app is now live with server-side rendering enabled. To verify SSR is working, load a page with JavaScript disabled — the content still renders.
