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

@available_since rails=3.11.0

Whether to include an empty `errors` hash in the props when no validation errors are present.

When set to `true`, an empty `errors: {}` object will always be included in Inertia responses. When set to `false`, the `errors` key will be omitted when there are no errors. The default value `nil` currently behaves like `false` but shows a deprecation warning.

The default value will be changed to `true` in the next major version.

### `parent_controller`

**Default**: `'::ApplicationController'`
**ENV**: `INERTIA_PARENT_CONTROLLER`

Specifies the base controller class for the internal `StaticController` used to render [Shorthand routes](/guide/routing#shorthand-routes).

By default, Inertia Rails creates a `StaticController` that inherits from `ApplicationController`. You can use this option to specify a different base controller (for example, to include custom authentication, layout, or before actions).

### `root_dom_id`

**Default**: `'app'`
**ENV**: `INERTIA_ROOT_DOM_ID`

@available_since rails=3.15.0

Specifies the DOM element ID used for the root Inertia.js element.

```ruby
InertiaRails.configure do |config|
  config.root_dom_id = 'inertia-app'
end
```

> [!NOTE]
> Make sure your client-side Inertia setup uses the same ID when calling `createInertiaApp`.

### `use_script_element_for_initial_page`

**Default**: `false`
**ENV**: `INERTIA_USE_SCRIPT_ELEMENT_FOR_INITIAL_PAGE`

@available_since rails=3.15.0 core=2.2.20

When enabled the initial page data is rendered in a `<script type="application/json">` element instead of the `data-page` attribute on the root `<div>`.
This provides two main benefits:

1. **Smaller page size**: JSON data doesn't require HTML entity encoding, reducing the overall HTML payload size.
2. **Faster parsing**: The browser can parse raw JSON directly from the script element, which is more efficient than parsing HTML-encoded JSON from an attribute.

```ruby
InertiaRails.configure do |config|
  config.use_script_element_for_initial_page = true
end
```

When disabled (default), the HTML output looks like:

```html
<div id="app" data-page='{"component":"Users/Index",...}'></div>
```

When enabled, the HTML output looks like:

```html
<script data-page="app" type="application/json">
  {"component":"Users/Index",...}
</script>
<div id="app"></div>
```

> [!NOTE]
> When using this option make sure your client-side Inertia setup is configured to read the page data from the `<script>` element.
> See the [client side setup](/guide/client-side-setup#script-element-for-page-data) for more details.
