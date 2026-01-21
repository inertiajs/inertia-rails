# Testing

There are many different ways to test an Inertia.js app. This page provides a quick overview of the tools available.

## End-to-end tests

One popular approach to testing your JavaScript page components, is to use an end-to-end testing tool like [Capybara](https://github.com/teamcapybara/capybara) or [Cypress](https://www.cypress.io). These are browser automation tools that allow you to run real simulations of your app in the browser. These tests are known to be slower, and sometimes brittle, but since they test your application at the same layer as your end users, they can provide a lot of confidence that your app is working correctly. And, since these tests are run in the browser your JavaScript code is actually executed and tested as well.

## Client-side unit tests

Another approach to testing your page components is using a client-side unit testing framework, such as [Vitest](https://vitest.dev), [Jest](https://jestjs.io) or [Mocha](https://mochajs.org). This approach allows you to test your JavaScript page components in isolation using Node.js.

## Endpoint tests

In addition to testing your JavaScript page components, you'll also want to test the Inertia responses that come back from your server-side framework. A popular approach to doing this is using endpoint tests, where you make requests to your application and examine the responses.

Inertia Rails provides test helpers for both RSpec and Minitest.

### RSpec

To use RSpec helpers, add the following require statement to your `spec/rails_helper.rb`:

```ruby
require 'inertia_rails/rspec'
```

The helpers are automatically available in all request specs. No additional setup needed.

#### Assertions

Inertia Rails provides several RSpec matchers for testing Inertia responses:

| Matcher                | Description                                                        |
| ---------------------- | ------------------------------------------------------------------ |
| `be_inertia_response`  | Assert the response is an Inertia response                         |
| `render_component`     | Assert the rendered component name                                 |
| `have_props`           | Assert props contain expected key/value pairs (partial match)      |
| `have_exact_props`     | Assert props match exactly                                         |
| `have_no_prop`         | Assert a prop key doesn't exist                                    |
| `have_view_data`       | Assert view_data contains expected key/value pairs (partial match) |
| `have_exact_view_data` | Assert view_data matches exactly                                   |
| `have_no_view_data`    | Assert a view_data key doesn't exist                               |
| `have_flash`           | Assert flash contains expected key/value pairs (partial match)     |
| `have_exact_flash`     | Assert flash matches exactly                                       |
| `have_no_flash`        | Assert a flash key doesn't exist                                   |
| `have_deferred_props`  | Assert props are deferred (optionally in a specific group)         |

```ruby
# spec/requests/events_spec.rb
RSpec.describe '/events' do
  describe '#index' do
    let!(:event) { Event.create!(title: 'Rails World', start_date: '2026-09-23', description: 'Annual Ruby on Rails conference') }

    it 'renders inertia component' do
      get events_path

      # Assert this is an Inertia response
      expect(inertia).to be_inertia_response

      # Assert component name
      expect(inertia).to render_component 'events/index'

      # Assert props (partial match)
      expect(inertia).to have_props(title: 'Rails World')

      # Assert props (exact match)
      expect(inertia).to have_exact_props(title: 'Rails World', description: 'Annual Ruby on Rails conference')

      # Access props directly (supports both symbol and string keys)
      expect(inertia.props[:title]).to eq 'Rails World'
      expect(inertia.props['title']).to eq 'Rails World'

      # Assert view_data (partial match)
      expect(inertia).to have_view_data(timezone: 'UTC')

      # Assert view_data (exact match)
      expect(inertia).to have_exact_view_data(timezone: 'UTC')

      # Access view_data directly
      expect(inertia.view_data[:timezone]).to eq 'UTC'

      # Assert prop doesn't exist
      expect(inertia).not_to have_props(secret: anything)
    end
  end
end
```

#### Flash data

```ruby
RSpec.describe '/events' do
  it 'shows flash message after create' do
    post events_path, params: { event: { title: 'New Event' } }

    # Assert flash contains key/value (partial match)
    expect(inertia).to have_flash(notice: 'Event created!')

    # Assert flash matches exactly
    expect(inertia).to have_exact_flash(notice: 'Event created!')

    # Access flash directly
    expect(inertia.flash[:notice]).to eq 'Event created!'

    # Assert flash key doesn't exist
    expect(inertia).not_to have_flash(alert: anything)
  end
end
```

#### Validation errors

```ruby
RSpec.describe '/events' do
  it 'returns validation errors' do
    post events_path, params: { event: { title: '' } }

    expect(inertia).to render_component 'events/new'
    expect(inertia).to have_props(errors: { title: ["can't be blank"] })
  end
end
```

#### Redirects with flash

```ruby
RSpec.describe '/events' do
  it 'redirects after create' do
    post events_path, params: { event: { title: 'Conference' } }
    follow_redirect!

    expect(inertia).to render_component 'events/show'
    expect(inertia).to have_flash(notice: 'Event created!')
  end
end
```

#### Deferred props

```ruby
RSpec.describe '/events' do
  it 'defers expensive data' do
    get events_path

    # Assert deferred props exist
    expect(inertia).to have_deferred_props

    # Assert specific props are deferred (checks :default group)
    expect(inertia).to have_deferred_props(:analytics)
    expect(inertia).to have_deferred_props(:analytics, :statistics)

    # Assert props are deferred in a non-default group
    expect(inertia).to have_deferred_props(:other_data, group: :slow)

    # Access deferred props directly
    expect(inertia.deferred_props[:default]).to include(:analytics)

    # Deferred props are not in regular props on first load
    expect(inertia.props[:analytics]).to be_nil
  end
end
```

#### Partial reload helpers

RSpec provides helpers to test partial reloads and deferred prop loading:

```ruby
RSpec.describe '/events' do
  it 'supports partial reloads' do
    get events_path

    # Reload only specific props
    inertia_reload_only(:analytics, :statistics)
    expect(inertia.props[:analytics]).to be_present

    # Reload all props except specific ones
    inertia_reload_except(:expensive_data)

    # Load deferred props by group
    inertia_load_deferred_props(:default)

    # Load all deferred props
    inertia_load_deferred_props
  end
end
```

### Minitest

To use Minitest helpers, add the following require statement to your `test/test_helper.rb`:

```ruby
require 'inertia_rails/minitest'
```

The helpers are automatically included in `ActionDispatch::IntegrationTest`.

#### Assertions

Inertia Rails provides Rails-like assertions for testing Inertia responses:

| Assertion                        | Description                                                        |
| -------------------------------- | ------------------------------------------------------------------ |
| `assert_inertia_response`        | Assert the response is an Inertia response                         |
| `refute_inertia_response`        | Assert the response is not an Inertia response                     |
| `assert_inertia_component`       | Assert the rendered component name                                 |
| `refute_inertia_component`       | Assert the rendered component is not the given value               |
| `assert_inertia_props`           | Assert props contain expected key/value pairs (partial match)      |
| `refute_inertia_props`           | Assert props don't contain expected key/value pairs                |
| `assert_inertia_props_equal`     | Assert props match exactly                                         |
| `refute_inertia_props_equal`     | Assert props don't match exactly                                   |
| `assert_no_inertia_prop`         | Assert a prop key doesn't exist                                    |
| `assert_inertia_view_data`       | Assert view_data contains expected key/value pairs (partial match) |
| `refute_inertia_view_data`       | Assert view_data doesn't contain expected key/value pairs          |
| `assert_inertia_view_data_equal` | Assert view_data matches exactly                                   |
| `refute_inertia_view_data_equal` | Assert view_data doesn't match exactly                             |
| `assert_no_inertia_view_data`    | Assert a view_data key doesn't exist                               |
| `assert_inertia_flash`           | Assert flash contains expected key/value pairs (partial match)     |
| `refute_inertia_flash`           | Assert flash doesn't contain expected key/value pairs              |
| `assert_inertia_flash_equal`     | Assert flash matches exactly                                       |
| `refute_inertia_flash_equal`     | Assert flash doesn't match exactly                                 |
| `assert_no_inertia_flash`        | Assert a flash key doesn't exist                                   |
| `assert_inertia_deferred_props`  | Assert props are deferred (optionally in a specific group)         |
| `refute_inertia_deferred_props`  | Assert props are not deferred (or not in a specific group)         |

```ruby
# test/integration/events_test.rb
class EventsTest < ActionDispatch::IntegrationTest
  test 'renders inertia component' do
    event = Event.create!(title: 'Rails World', start_date: '2026-09-23', description: 'Annual Ruby on Rails conference')

    get events_path

    # Assert this is an Inertia response
    assert_inertia_response

    # Assert component name
    assert_inertia_component 'events/index'

    # Assert props (partial match)
    assert_inertia_props title: 'Rails World'

    # Assert props (exact match)
    assert_inertia_props_equal title: 'Rails World', description: 'Annual Ruby on Rails conference'

    # Access props directly (supports both symbol and string keys)
    assert_equal 'Rails World', inertia.props[:title]
    assert_equal 'Rails World', inertia.props['title']

    # Assert view_data (partial match)
    assert_inertia_view_data timezone: 'UTC'

    # Assert view_data (exact match)
    assert_inertia_view_data_equal timezone: 'UTC'

    # Access view_data directly
    assert_equal 'UTC', inertia.view_data[:timezone]

    # Assert view_data key doesn't exist
    assert_no_inertia_view_data :secret

    # Assert prop doesn't exist
    assert_no_inertia_prop :secret
  end
end
```

#### Flash data

```ruby
class EventsTest < ActionDispatch::IntegrationTest
  test 'shows flash message after create' do
    post events_path, params: { event: { title: 'New Event' } }

    # Assert flash contains key/value (partial match)
    assert_inertia_flash notice: 'Event created!'

    # Assert flash matches exactly
    assert_inertia_flash_equal notice: 'Event created!'

    # Access flash directly
    assert_equal 'Event created!', inertia.flash[:notice]

    # Assert flash key doesn't exist
    assert_no_inertia_flash :alert
  end
end
```

#### Validation errors

```ruby
class EventsTest < ActionDispatch::IntegrationTest
  test 'returns validation errors' do
    post events_path, params: { event: { title: '' } }

    assert_inertia_component 'events/new'
    assert_inertia_props errors: { title: ["can't be blank"] }
  end
end
```

#### Redirects with flash

```ruby
class EventsTest < ActionDispatch::IntegrationTest
  test 'redirects after create' do
    post events_path, params: { event: { title: 'Conference' } }
    follow_redirect!

    assert_inertia_component 'events/show'
    assert_inertia_flash notice: 'Event created!'
  end
end
```

#### Deferred props

```ruby
class EventsTest < ActionDispatch::IntegrationTest
  test 'defers expensive data' do
    get events_path

    # Assert deferred props exist
    assert_inertia_deferred_props

    # Assert specific props are deferred (checks :default group)
    assert_inertia_deferred_props :analytics
    assert_inertia_deferred_props :analytics, :statistics

    # Assert props are deferred in a non-default group
    assert_inertia_deferred_props :other_data, group: :slow

    # Access deferred props directly
    assert_includes inertia.deferred_props[:default], :analytics

    # Deferred props are not in regular props on first load
    assert_nil inertia.props[:analytics]
  end
end
```

#### Partial reload helpers

Minitest provides helpers to test partial reloads and deferred prop loading:

```ruby
class EventsTest < ActionDispatch::IntegrationTest
  test 'supports partial reloads' do
    get events_path

    # Reload only specific props
    inertia_reload_only(:analytics, :statistics)
    assert_not_nil inertia.props[:analytics]

    # Reload all props except specific ones
    inertia_reload_except(:expensive_data)

    # Load deferred props by group
    inertia_load_deferred_props(:default)

    # Load all deferred props
    inertia_load_deferred_props
  end
end
```
