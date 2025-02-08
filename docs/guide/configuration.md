# Configuration

Inertia Rails can be configured globally or in a specific controller (and subclasses).

## Global Configuration

If using global configuration, we recommend you place the code inside an initializer:

```ruby
# config/initializers/inertia.rb

InertiaRails.configure do |config|
  # Example: force a full-reload if the deployed assets change.
  config.version = ViteRuby.digest
end
```

The default configuration can be found [here](https://github.com/inertiajs/inertia-rails/blob/master/lib/inertia_rails/configuration.rb#L5).

## Local Configuration

Use `inertia_config` in your controllers to override global settings:

```ruby
class EventsController < ApplicationController
  inertia_config(
    version: "events-#{InertiaRails.configuration.version}",
    ssr_enabled: -> { action_name == "index" },
  )
end
```

## Configuration Options

### `component_path_resolver`

Use `component_path_resolver` to customize component path resolution when [`default_render`](#default_render) config value is set to `true`. The value should be callable and will receive the `path` and `action` parameters, returning a string component path. See [Automatically determine component name](/guide/responses#automatically-determine-component-name).

**Default**: `->(path:, action:) { "#{path}/#{action}" }`

### `deep_merge_shared_data`

When enabled, props will be deep merged with shared data, combining hashes
with the same keys instead of replacing them.

**Default**: `false`

### `default_render`

Overrides Rails default rendering behavior to render using Inertia by default.

**Default**: `false`

### `encrypt_history`

When enabled, you instruct Inertia to encrypt your app's history, it uses
the browser's built-in [`crypto` api](https://developer.mozilla.org/en-US/docs/Web/API/Crypto)
to encrypt the current page's data before pushing it to the history state.

**Default**: `false`

### `ssr_enabled` _(experimental)_

Whether to use a JavaScript server to pre-render your JavaScript pages,
allowing your visitors to receive fully rendered HTML when they first visit
your application.

Requires a JS server to be available at `ssr_url`. [_Example_](https://github.com/ElMassimo/inertia-rails-ssr-template)

**Default**: `false`

### `ssr_url` _(experimental)_

The URL of the JS server that will pre-render the app using the specified
component and props.

**Default**: `"http://localhost:13714"`

### `version` _(recommended)_

This allows Inertia to detect if the app running in the client is oudated,
forcing a full page visit instead of an XHR visit on the next request.

See [assets versioning](https://inertiajs.com/asset-versioning).

**Default**: `nil`
