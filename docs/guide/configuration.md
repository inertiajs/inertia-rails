# Configuration

Inertia Rails can be configured globally or in a specific controller (and subclasses).

## Global Configuration

Use the `InertiaRails.configure` method to set global configuration options. If using global configuration, we recommend you place the code inside an initializer:

```ruby
# config/initializers/inertia.rb

InertiaRails.configure do |config|
  # Example: force a full-reload if the deployed assets change.
  config.version = ViteRuby.digest
end
```

The default configuration can be found [here](https://github.com/inertiajs/inertia-rails/blob/master/lib/inertia_rails/configuration.rb#L5).

## Local Configuration

The `inertia_config` method allows you to override global settings in specific controllers. Use this method in your controllers to customize configuration for specific parts of your application:

```ruby
class EventsController < ApplicationController
  inertia_config(
    version: "events-#{InertiaRails.configuration.version}",
    ssr_enabled: -> { action_name == "index" },
  )
end
```

## Setting Configuration via Environment Variables

Inertia Rails supports setting any configuration option via environment variables out of the box. For each option in the configuration, you can set an environment variable prefixed with `INERTIA_` and the option name in uppercase. For example: `INERTIA_SSR_ENABLED`.

**Boolean values** (like `INERTIA_DEEP_MERGE_SHARED_DATA` or `INERTIA_SSR_ENABLED`) are parsed from the strings `"true"` or `"false"` (case-sensitive).

## Configuration Options

### `component_path_resolver`

**Default**: `->(path:, action:) { "#{path}/#{action}" }`

Use `component_path_resolver` to customize component path resolution when [`default_render`](#default_render) config value is set to `true`. The value should be callable and will receive the `path` and `action` parameters, returning a string component path. See [Automatically determine component name](/guide/responses#automatically-determine-component-name).

### `deep_merge_shared_data`

**Default**: `false`  
**ENV**: `INERTIA_DEEP_MERGE_SHARED_DATA`

When enabled, props will be deep merged with shared data, combining hashes
with the same keys instead of replacing them.

### `default_render`

**Default**: `false`  
**ENV**: `INERTIA_DEFAULT_RENDER`

Overrides Rails default rendering behavior to render using Inertia by default.

### `encrypt_history`

**Default**: `false`  
**ENV**: `INERTIA_ENCRYPT_HISTORY`

When enabled, you instruct Inertia to encrypt your app's history, it uses
the browser's built-in [`crypto` api](https://developer.mozilla.org/en-US/docs/Web/API/Crypto)
to encrypt the current page's data before pushing it to the history state.

### `ssr_enabled` _(experimental)_

**Default**: `false`  
**ENV**: `INERTIA_SSR_ENABLED`

Whether to use a JavaScript server to pre-render your JavaScript pages,
allowing your visitors to receive fully rendered HTML when they first visit
your application.

Requires a JS server to be available at `ssr_url`. [_Example_](https://github.com/ElMassimo/inertia-rails-ssr-template)

### `ssr_url` _(experimental)_

**Default**: `"http://localhost:13714"`
**ENV**: `INERTIA_SSR_URL`

The URL of the JS server that will pre-render the app using the specified
component and props.

### `version` _(recommended)_

**Default**: `nil`
**ENV**: `INERTIA_VERSION`

This allows Inertia to detect if the app running in the client is oudated,
forcing a full page visit instead of an XHR visit on the next request.

See [assets versioning](/guide/asset-versioning).

### `parent_controller`

**Default**: `'::ApplicationController'`
**ENV**: `INERTIA_PARENT_CONTROLLER`

Specifies the base controller class for the internal `StaticController` used to render [Shorthand routes](/guide/routing#shorthand-routes).

By default, Inertia Rails creates a `StaticController` that inherits from `ApplicationController`. You can use this option to specify a different base controller (for example, to include custom authentication, layout, or before actions).
