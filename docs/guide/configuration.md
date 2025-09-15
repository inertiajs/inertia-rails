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

### `prop_transformer`

**Default**: `->(props:) { props }`

Use `prop_transformer` to apply a transformation to your props before they're sent to the view. One use-case this enables is to work with `snake_case` props within Rails while working with `camelCase` in your view:

```ruby
  inertia_config(
    prop_transformer: lambda do |props:|
      props.deep_transform_keys { |key| key.to_s.camelize(:lower) }
    end
  )
```

> [!NOTE]
> This controls the props provided by Inertia Rails but does not concern itself with props coming _into_ Rails. You may want to add a global `before_action` to `ApplicationController`:

```ruby
before_action :underscore_params

# ...

def underscore_params
  params.deep_transform_keys! { |key| key.to_s.underscore }
end
```

### `merge_prop_transformer`

**Default**: `->(merge_props:) { merge_props }`

Use `merge_prop_transformer` to apply a transformation to the array of merge prop keys before they're sent to the client. This is particularly useful to maintain consistency when using `prop_transformer` to convert prop keys to `camelCase`, as it ensures that merge props (used with `InertiaRails.merge` and `InertiaRails.deep_merge`) also follow the same naming convention:

```ruby
  inertia_config(
    prop_transformer: lambda do |props:|
      props.deep_transform_keys { |key| key.to_s.camelize(:lower) }
    end,
    merge_prop_transformer: lambda do |merge_props:|
      merge_props.map { |prop| prop.to_s.camelize(:lower) }
    end
  )
```

Without `merge_prop_transformer`, you would have inconsistent naming where regular props use `camelCase` but merge prop keys remain in `snake_case`. This transformer only affects the array of merge prop keys that gets sent to the client in the `mergeProps` and `deepMergeProps` fields.

### `deep_merge_shared_data`

**Default**: `false`
**ENV**: `INERTIA_DEEP_MERGE_SHARED_DATA`

@available_since rails=3.8.0

When enabled, props will be deep merged with shared data, combining hashes
with the same keys instead of replacing them.

### `default_render`

**Default**: `false`
**ENV**: `INERTIA_DEFAULT_RENDER`

Overrides Rails default rendering behavior to render using Inertia by default.

### `encrypt_history`

**Default**: `false`
**ENV**: `INERTIA_ENCRYPT_HISTORY`

@available_since rails=3.7.0 core=2.0.0

When enabled, you instruct Inertia to encrypt your app's history, it uses
the browser's built-in [`crypto` api](https://developer.mozilla.org/en-US/docs/Web/API/Crypto)
to encrypt the current page's data before pushing it to the history state.

### `ssr_enabled` _(experimental)_

**Default**: `false`
**ENV**: `INERTIA_SSR_ENABLED`

@available_since rails=3.6.0 core=2.0.0

Whether to use a JavaScript server to pre-render your JavaScript pages,
allowing your visitors to receive fully rendered HTML when they first visit
your application.

Requires a JavaScript server to be available at `ssr_url`. [_Example_](https://github.com/ElMassimo/inertia-rails-ssr-template)

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

### `always_include_errors_hash`

**Default**: `nil`
**ENV**: `INERTIA_ALWAYS_INCLUDE_ERRORS_HASH`

@available_since rails=master

Whether to include an empty `errors` hash in the props when no validation errors are present.

When set to `true`, an empty `errors: {}` object will always be included in Inertia responses. When set to `false`, the `errors` key will be omitted when there are no errors. The default value `nil` currently behaves like `false` but shows a deprecation warning.

The default value will be changed to `true` in the next major version.

### `parent_controller`

**Default**: `'::ApplicationController'`
**ENV**: `INERTIA_PARENT_CONTROLLER`

Specifies the base controller class for the internal `StaticController` used to render [Shorthand routes](/guide/routing#shorthand-routes).

By default, Inertia Rails creates a `StaticController` that inherits from `ApplicationController`. You can use this option to specify a different base controller (for example, to include custom authentication, layout, or before actions).
