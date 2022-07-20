![image](https://user-images.githubusercontent.com/6599653/114456558-032e2200-9bab-11eb-88bc-a19897f417ba.png)


# Inertia.js Rails Adapter

## Installation

### Backend

Just add the inertia rails gem to your Gemfile
```ruby
gem 'inertia_rails'
```

### Frontend

Rails 7 specific frontend docs coming soon. For now, check out the official Inertia docs at https://inertiajs.com/

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

### Shared Data

If you have data that you want to be provided as a prop to every component (a common use-case is informationa about the authenticated user) you can use the `shared_data` controller method.

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

### Routing

If you don't need a controller to handle a static component, you can route directly to a component with the inertia route helper

```ruby
inertia 'about' => 'AboutComponent'
```

## Configuration

Inertia Rails has a few different configuration options that can be set anywhere, but the most common location is from within an initializer.

The default config is shown below
```ruby
InertiaRails.configure do |config|
  
  # set the current version for automatic asset refreshing. A string value should be used if any.
  config.version = nil
  
  # set the layout you want inertia components to be rendered within. This layout must include any required inertia javascript.
  config.layout = 'application'

  # ssr specific options
  config.ssr_enabled = false
  config.ssr_url = 'http://localhost:13714'
  
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
