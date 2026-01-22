# Deploy with `Kamal`

Rails 8 will ship with [Kamal](https://kamal-deploy.org/) preconfigured as the default deployment tool.
If your application does not require [SSR](/guide/server-side-rendering.md), you simply just need to
[update your asset_path](#update-asset-path-inconfig-deploy-yml), and deployment should work seamlessly.

However, if you plan to configure your Inertia Rails application with [SSR](/guide/server-side-rendering.md) enabled,
a few additional tweaks may be required. This guide will walk you through the steps to quickly configure
[Kamal](https://kamal-deploy.org/) for deploying your next Inertia Rails application with
[SSR](/guide/server-side-rendering.md) support.

> Note: This guide is based on Rails 8.0 and Kamal 2.3.0 at the time of writing.


## Update your Dockerfile

It is crucial to ensure that the **_Install JavaScript dependencies_** step is executed in the **_base_** image. This
guarantees that the Node.js runtime is available for both the **_build_** stage and the **_runtime_** stage.

```dockerfile
# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t fresh_rails .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name fresh_rails fresh_rails

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.6
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install JavaScript dependencies // [!code ++]
ARG NODE_VERSION=22.11.0 // [!code ++]
ARG YARN_VERSION=1.22.22 // [!code ++]
ENV PATH=/usr/local/node/bin:$PATH // [!code ++]
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \ // [!code ++]
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \ // [!code ++]
    npm install -g yarn@$YARN_VERSION && \ // [!code ++]
    rm -rf /tmp/node-build-master // [!code ++]

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems and node modules  // [!code ++]
# Install packages needed to build gems  // [!code --]
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev node-gyp pkg-config python-is-python3 && \ // [!code ++]
    apt-get install --no-install-recommends -y build-essential git pkg-config && \ // [!code --]
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY .ruby-version Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Install node modules // [!code ++]
COPY package.json yarn.lock ./ // [!code ++]
RUN yarn install --frozen-lockfile // [!code ++]

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

RUN rm -rf node_modules // [!code ++]


# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
```


## Setup server role to run SSR server in `config/deploy.yml`

The Node-based Inertia SSR server is used to pre-render pages on the server before sending them to the client.
The `vite_ssr` role ensures that the SSR server runs separately from the main Rails app server.

```yml
# Deploy to these servers.
servers:
  web:
    - 192.168.0.1
  vite_ssr: // [!code ++]
    hosts: // [!code ++]
      - 192.168.0.1 // [!code ++]
    cmd: bundle exec vite ssr // [!code ++]
    options: // [!code ++]
      network-alias: vite_ssr // [!code ++]
  # job:
  #   hosts:
  #     - 192.168.0.1
  #   cmd: bin/jobs
```


## Specify the Vite server in `config/deploy.yml`

The Rails app needs to know where to send SSR requests. Add the `VITE_RUBY_HOST` environment variable
to ensure your Rails application can connect to the correct SSR server. The value **_VITE_RUBY_HOST: "vite_ssr"_**
must match the **_network-alias_** defined in the `vite_ssr` role above.

```yml
# Inject ENV variables into containers (secrets come from .kamal/secrets).
env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    # Run the Solid Queue Supervisor inside the web server's Puma process to do jobs.
    # When you start using multiple servers, you should split out job processing to a dedicated machine.
    SOLID_QUEUE_IN_PUMA: true

    VITE_RUBY_HOST: "vite_ssr" // [!code ++]

    # Set number of processes dedicated to Solid Queue (default: 1)
    # JOB_CONCURRENCY: 3

    # Set number of cores available to the application on each server (default: 1).
    # WEB_CONCURRENCY: 2

    # Match this to any external database server to configure Active Record correctly
    # Use inertia_rails_svelte5_ssr-db for a db accessory server on same machine via local kamal docker network.
    # DB_HOST: 192.168.0.2

    # Log everything from Rails
    # RAILS_LOG_LEVEL: debug

```


## Update asset_path in`config/deploy.yml`

Update the asset_path to `/rails/public/vite` if you haven't.

```yml
# Bridge fingerprinted assets, like JS and CSS, between versions to avoid
# hitting 404 on in-flight requests. Combines all files from new and old
# version inside the asset_path.
asset_path: /rails/public/assets // [!code --]
asset_path: /rails/public/vite // [!code ++]
```


## Ensure that your `vite.config.ts` is configured to support SSR

Configure Vite with an `ssr` block in your `vite.config.ts` file to ensures all dependencies are bundled for SSR.

```js
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { defineConfig } from 'vite'
import ViteRails from "vite-plugin-rails"

export default defineConfig({
    ssr: {// [!code ++]
        noExternal: true,// [!code ++]
    },// [!code ++]
    plugins: [
        svelte(),
        ViteRails({
            envVars: { RAILS_ENV: "development" },
            envOptions: { defineOn: "import.meta.env" },
            fullReload: {
                additionalPaths: [],
            },
        }),
    ],
})
```

## Configure SSR URL in the Inertia's Rails adapter

To enable Server-Side Rendering (SSR) in your Inertia Rails application, you need to specify
the correct SSR server URL in the adapter. It can be set via the `INERTIA_SSR_URL` ENV variable.


## Deploy and enjoy 🎉

Once everything is set up, you can deploy your application by running:

* `kamal setup` (if you haven’t provisioned the server yet).
* `kamal deploy` (to deploy your application).

In just a few minutes, your application will be live and ready, complete with SSR support! 🎉
Good luck, and happy deploying! 🚀
