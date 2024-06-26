![image](https://user-images.githubusercontent.com/6599653/114456558-032e2200-9bab-11eb-88bc-a19897f417ba.png)


# Inertia.js Rails Adapter

## Installation

### Backend

Just add the inertia rails gem to your Gemfile
```ruby
gem 'inertia_rails'
```

### Frontend

Rails 7 specific frontend docs coming soon. For now, check out the official Inertia docs at https://inertiajs.com/ or see an example using React/Vite [here](https://github.com/BrandonShar/inertia-rails-template)

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

Automatic component name is also opt in, you must set the `default_render` config value to `true`. Otherwise, you can simply `render inertia: true` for the same behavior explicitly. 

### Layout 

Inertia layouts use the rails layout convention and can be set or changed in the same way. The original `layout` config option is still functional, but will likely be deprecated in the future in favor
of using rails layouts.

```ruby
class EventsController < ApplicationController
  layout 'inertia_application'
end
```


### Shared Data

If you have data that you want to be provided as a prop to every component (a common use-case is information about the authenticated user) you can use the `shared_data` controller method.

```ruby
class EventsController < ApplicationController
  # share syncronously
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

Deep merging can be set as the project wide default via the InertiaRails configuration:

```ruby
# config/initializers/some_initializer.rb
InertiaRails.configure do |config|
  config.deep_merge_shared_data = true
end

```

If deep merging is enabled by default, it's possible to opt out within the action:

```ruby
class CrazyScorersController < ApplicationController
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

# Even if deep merging is set by default, since the renderer has `deep_merge: false`, it will send a shallow merge to the frontend:
{
  basketball_data: {
    points: 100,
  }
}
```

### Lazy Props

On the front end, Inertia supports the concept of "partial reloads" where only the props requested are returned by the server. Sometimes, you may want to use this flow to avoid processing a particularly slow prop on the intial load. In this case, you can use Lazy props. Lazy props aren't evaluated unless they're specifically requested by name in a partial reload.

```ruby
  inertia_share some_data: InertiaRails.lazy(lambda { some_very_slow_method })
```

### Routing

If you don't need a controller to handle a static component, you can route directly to a component with the inertia route helper

```ruby
inertia 'about' => 'AboutComponent'
```

### SSR

Enable SSR via the config settings for `ssr_enabled` and `ssr_url`.

When using SSR, don't forget to add `<%= inertia_ssr_head %>` to the `<head>` of your `application.html.erb`.

## Configuration

Inertia Rails has a few different configuration options that can be set anywhere, but the most common location is from within an initializer.

The default config is shown below
```ruby
InertiaRails.configure do |config|
  
  # set the current version for automatic asset refreshing. A string value should be used if any.
  config.version = nil
  # enable default inertia rendering (warning! this will override rails default rendering behavior)
  config.default_render = true
  
  # ssr specific options
  config.ssr_enabled = false
  config.ssr_url = 'http://localhost:13714'

  config.deep_merge_shared_data = false
  
end
```

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
