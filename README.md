![image](https://user-images.githubusercontent.com/6599653/114456558-032e2200-9bab-11eb-88bc-a19897f417ba.png)


# Inertia.js Rails Adapter

## Installation

### Backend

Add the `inertia_rails` gem to your Gemfile.

```ruby
gem 'inertia_rails'
```

Follow the complete [Server-side setup](https://inertia-rails.dev/guide/server-side-setup) in the official documentation.

### Frontend

Follow the [Client-side setup](https://inertia-rails.dev/guide/client-side-setup) guide for detailed configuration steps.

### Example Projects:

Reference these sample implementations:

- [React/Vite](https://github.com/BrandonShar/inertia-rails-template)
- [React/Vite + SSR](https://github.com/ElMassimo/inertia-rails-ssr-template)
- [PingCRM with Vue and Vite](https://github.com/ledermann/pingcrm)

## Usage

### Responses

Render Inertia responses is simple, just use the inertia renderer in your controller methods. The renderer accepts two arguments, the first is the name of the component you want to render from within your pages directory (without extension). The second argument is an options hash where you can provide `props` to your components. This options hash also allows you to pass `view_data` to your layout, but this is much less common.

```ruby
def index
  render inertia: 'Event/Index', props: {
    events: Event.all,
  }
end
```

#### Rails Component and Instance Props 

Starting in version 3.0, Inertia Rails allows you to provide your component name and props via common rails conventions. 

```ruby
class EventsController < ApplicationController
  use_inertia_instance_props

  def index
    @events = Event.all
  end

end
```

is the same as 


```ruby
class EventsController < ApplicationController
  def index
    render inertia: 'events/index', props: {
      events: Event.all
    }
  end
end
```

#### Instance Props and Default Render Notes 

In order to use instance props, you must call `use_inertia_instance_props` on the controller (or a base controller it inherits from). If any props are provided manually, instance props
are automatically disabled for that response. Instance props are only included if they are defined after the before filter is set from `use_inertia_instance_props`.

Automatic component name is also opt in, you must set the [`default_render`](#default_render) config value to `true`. Otherwise, you can simply `render inertia: true` for the same behavior explicitly.

If the default component path doesn't match your convention, you can define a method to resolve it however you like via the `component_path_resolver` config value. The value of this should be callable and will receive the path and action and should return a string component path.

```ruby
inertia_config(
  component_path_resolver: ->(path:, action:) do
    "Storefront/#{path.camelize}/#{action.camelize}"
  end
)

```



### Layout 

Inertia layouts use the rails layout convention and can be set or changed in the same way.

```ruby
class EventsController < ApplicationController
  layout 'inertia_application'
end
```


### Shared Data

If you have data that you want to be provided as a prop to every component (a common use-case is information about the authenticated user) you can use the `inertia_share` controller method.

```ruby
class EventsController < ApplicationController
  # share synchronously
  inertia_share app_name: env['app.name']
  
  # share lazily, evaluated at render time
  inertia_share do
    if logged_in?
      {
        user: logged_in_user,
      }
    end
  end
  
  # share lazily alternate syntax
  inertia_share user_count: lambda { User.count }
  
end
```

#### Deep Merging Shared Data

By default, Inertia will shallow merge data defined in an action with the shared data. You might want a deep merge. Imagine using shared data to represent defaults you'll override sometimes.

```ruby
class ApplicationController
  inertia_share do
    { basketball_data: { points: 50, rebounds: 100 } }
  end
end
```

Let's say we want a particular action to change only part of that data structure. The renderer accepts a `deep_merge` option:

```ruby
class CrazyScorersController < ApplicationController
  def index
    render inertia: 'CrazyScorersComponent',
    props: { basketball_data: { points: 100 } },
    deep_merge: true
  end
end

# The renderer will send this to the frontend:
{
  basketball_data: {
    points: 100,
    rebounds: 100,
  }
}
```

Deep merging can be configured using the [`deep_merge_shared_data`](#deep_merge_shared_data) configuration option.

If deep merging is enabled, you can still opt-out within the action:

```ruby
class CrazyScorersController < ApplicationController
  inertia_config(deep_merge_shared_data: true)

  inertia_share do
    {
      basketball_data: {
        points: 50,
        rebounds: 10,
      }
    }
  end

  def index
    render inertia: 'CrazyScorersComponent',
    props: { basketball_data: { points: 100 } },
    deep_merge: false
  end
end

# `deep_merge: false` overrides the default:
{
  basketball_data: {
    points: 100,
  }
}
```

### Optional Props

On the frontend, Inertia supports the concept of "partial reloads" where only the props requested are returned by the server. Sometimes, you may want to use this flow to avoid processing a particularly slow prop on the initial load. In this case, you can use Optional props. Optional props aren't evaluated unless they're specifically requested by name in a partial reload.

```ruby
  inertia_share some_data: InertiaRails.optional { some_very_slow_method }
```

### Routing

If you don't need a controller to handle a static component, you can route directly to a component with the inertia route helper

```ruby
inertia 'about' => 'AboutComponent'
```

### SSR _(experimental)_

Enable SSR via the configuration options for [`ssr_enabled`](#ssr_enabled-experimental) and [`ssr_url`](#ssr_url-experimental).

When using SSR, don't forget to add `<%= inertia_ssr_head %>` to the `<head>` of your layout (i.e. `application.html.erb`).

## Configuration ⚙️

Inertia Rails can be configured globally or in a specific controller (and subclasses).

### Global Configuration

If using global configuration, we recommend you place the code inside an initializer:

```ruby
# config/initializers/inertia.rb

InertiaRails.configure do |config|
  # Example: force a full-reload if the deployed assets change.
  config.version = ViteRuby.digest
end
```

The default configuration can be found [here](https://github.com/inertiajs/inertia-rails/blob/master/lib/inertia_rails/configuration.rb#L5-L22).

### Local Configuration

Use `inertia_config` in your controllers to override global settings:

```ruby
class EventsController < ApplicationController
  inertia_config(
    version: "events-#{InertiaRails.configuration.version}",
    ssr_enabled: -> { action_name == "index" },
  )
end
```

### Configuration Options

#### `version` _(recommended)_

  This allows Inertia to detect if the app running in the client is oudated,
  forcing a full page visit instead of an XHR visit on the next request.

  See [assets versioning](https://inertiajs.com/asset-versioning).

  __Default__: `nil`

#### `deep_merge_shared_data`

  When enabled, props will be deep merged with shared data, combining hashes
  with the same keys instead of replacing them.

  __Default__: `false`

#### `default_render`

  Overrides Rails default rendering behavior to render using Inertia by default.

  __Default__: `false`

#### `encrypt_history`

  When enabled, you instruct Inertia to encrypt your app's history, it uses
  the browser's built-in [`crypto` api](https://developer.mozilla.org/en-US/docs/Web/API/Crypto)
  to encrypt the current page's data before pushing it to the history state.

  __Default__: `false`

#### `ssr_enabled` _(experimental)_

  Whether to use a JavaScript server to pre-render your JavaScript pages,
  allowing your visitors to receive fully rendered HTML when they first visit
  your application.

  Requires a JS server to be available at `ssr_url`. [_Example_](https://github.com/ElMassimo/inertia-rails-ssr-template)

  __Default__: `false`

#### `ssr_url` _(experimental)_

  The URL of the JS server that will pre-render the app using the specified
  component and props.

  __Default__: `"http://localhost:13714"`

## Testing

If you're using Rspec, Inertia Rails comes with some nice test helpers to make things simple. 

To use these helpers, just add the following require statement to your `spec/rails_helper.rb`

```ruby
require 'inertia_rails/rspec'
```

And in any test you want to use the inertia helpers, add the inertia flag to the describe block

```ruby
RSpec.describe EventController, type: :request do
  describe '#index', inertia: true do
    # ...
  end
end
```

### Assertions

```ruby
RSpec.describe EventController, type: :request do
  describe '#index', inertia: true do
    
    # check the component
    expect_inertia.to render_component 'Event/Index'
    
    # access the component name
    expect(inertia.component).to eq 'TestComponent'
    
    # props (including shared props)
    expect_inertia.to have_exact_props({name: 'Brandon', sport: 'hockey'})
    expect_inertia.to include_props({sport: 'hockey'})
    
    # access props
    expect(inertia.props[:name]).to eq 'Brandon'
    
    # view data
    expect_inertia.to have_exact_view_data({name: 'Brian', sport: 'basketball'})
    expect_inertia.to include_view_data({sport: 'basketball'})
    
    # access view data 
    expect(inertia.view_data[:name]).to eq 'Brian'
    
  end
end

```

*Maintained and sponsored by the team at [bellaWatt](https://bellawatt.com/)*

[![bellaWatt Logo](https://user-images.githubusercontent.com/6599653/114456832-5607d980-9bab-11eb-99c8-ab39867c384e.png)](https://bellawatt.com/)
