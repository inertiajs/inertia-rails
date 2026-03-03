# Testing

If you use end-to-end tools like [Capybara](https://github.com/teamcapybara/capybara) or client-side frameworks like [Vitest](https://vitest.dev), those work with Inertia out of the box. This page covers **endpoint tests** — testing the Inertia responses from your Rails backend.

## Setup

@available_since rails=3.17.0

Inertia Rails provides test helpers for both RSpec and Minitest.

:::tabs key:tests

== RSpec

```ruby
# spec/rails_helper.rb
require 'inertia_rails/rspec'
```

== Minitest

```ruby
# test/test_helper.rb
require 'inertia_rails/minitest'
```

:::

RSpec helpers are automatically available in all request specs. Minitest helpers are automatically included in `ActionDispatch::IntegrationTest`.

## Assertions

Both RSpec and Minitest provide matchers/assertions for testing Inertia responses. In RSpec, negation is done with `not_to`.

The `inertia` helper gives you direct access to `inertia.props`, `inertia.component`, `inertia.view_data`, `inertia.flash`, and `inertia.deferred_props`.

| Description               | RSpec                  | Minitest                                                            |
| ------------------------- | ---------------------- | ------------------------------------------------------------------- |
| Inertia response          | `be_inertia_response`  | `assert_inertia_response` / `refute_inertia_response`               |
| Component name            | `render_component`     | `assert_inertia_component` / `refute_inertia_component`             |
| Props (partial match)     | `have_props`           | `assert_inertia_props` / `refute_inertia_props`                     |
| Props (exact match)       | `have_exact_props`     | `assert_inertia_props_equal` / `refute_inertia_props_equal`         |
| Prop key absent           | `have_no_prop`         | `assert_no_inertia_prop`                                            |
| View data (partial match) | `have_view_data`       | `assert_inertia_view_data` / `refute_inertia_view_data`             |
| View data (exact match)   | `have_exact_view_data` | `assert_inertia_view_data_equal` / `refute_inertia_view_data_equal` |
| View data key absent      | `have_no_view_data`    | `assert_no_inertia_view_data`                                       |
| Flash (partial match)     | `have_flash`           | `assert_inertia_flash` / `refute_inertia_flash`                     |
| Flash (exact match)       | `have_exact_flash`     | `assert_inertia_flash_equal` / `refute_inertia_flash_equal`         |
| Flash key absent          | `have_no_flash`        | `assert_no_inertia_flash`                                           |
| Deferred props            | `have_deferred_props`  | `assert_inertia_deferred_props` / `refute_inertia_deferred_props`   |

:::tabs key:tests

== RSpec

```ruby
# spec/requests/events_spec.rb
RSpec.describe '/events' do
  describe '#index' do
    let!(:event) { Event.create!(title: 'Rails World', start_date: '2026-09-23', description: 'Annual Ruby on Rails conference') }

    it 'renders inertia component' do
      get events_path

      expect(inertia).to be_inertia_response
      expect(inertia).to render_component 'events/index'
      expect(inertia).to have_props(title: 'Rails World')
      expect(inertia).to have_exact_props(title: 'Rails World', start_date: '2026-09-23', description: 'Annual Ruby on Rails conference')

      # Props support both symbol and string keys
      expect(inertia.props[:title]).to eq 'Rails World'
      expect(inertia.props['title']).to eq 'Rails World'

      expect(inertia).to have_view_data(timezone: 'UTC')
      expect(inertia).to have_exact_view_data(timezone: 'UTC')
      expect(inertia.view_data[:timezone]).to eq 'UTC'

      expect(inertia).to have_no_prop(:secret)
    end
  end
end
```

== Minitest

```ruby
# test/integration/events_test.rb
class EventsTest < ActionDispatch::IntegrationTest
  test 'renders inertia component' do
    event = Event.create!(title: 'Rails World', start_date: '2026-09-23', description: 'Annual Ruby on Rails conference')

    get events_path

    assert_inertia_response
    assert_inertia_component 'events/index'
    assert_inertia_props title: 'Rails World'
    assert_inertia_props_equal title: 'Rails World', start_date: '2026-09-23', description: 'Annual Ruby on Rails conference'

    # Props support both symbol and string keys
    assert_equal 'Rails World', inertia.props[:title]
    assert_equal 'Rails World', inertia.props['title']

    assert_inertia_view_data timezone: 'UTC'
    assert_inertia_view_data_equal timezone: 'UTC'
    assert_equal 'UTC', inertia.view_data[:timezone]

    assert_no_inertia_view_data :secret
    assert_no_inertia_prop :secret
  end
end
```

:::

## Common testing tasks

### Test flash messages

Inertia Rails automatically shares [flash data](/guide/flash-data) with your frontend.

:::tabs key:tests

== RSpec

```ruby
RSpec.describe '/events' do
  it 'shows flash message after create' do
    post events_path, params: { event: { title: 'New Event' } }

    expect(inertia).to have_flash(notice: 'Event created!')
    expect(inertia).to have_exact_flash(notice: 'Event created!')
    expect(inertia.flash[:notice]).to eq 'Event created!'
    expect(inertia).to have_no_flash(:alert)
  end
end
```

== Minitest

```ruby
class EventsTest < ActionDispatch::IntegrationTest
  test 'shows flash message after create' do
    post events_path, params: { event: { title: 'New Event' } }

    assert_inertia_flash notice: 'Event created!'
    assert_inertia_flash_equal notice: 'Event created!'
    assert_equal 'Event created!', inertia.flash[:notice]
    assert_no_inertia_flash :alert
  end
end
```

:::

### Test validation errors

[Validation errors](/guide/validation) are shared as props automatically when using `redirect_to` with `inertia_errors`. Assert them on the `errors` key.

:::tabs key:tests

== RSpec

```ruby
RSpec.describe '/events' do
  it 'returns validation errors' do
    post events_path, params: { event: { title: '' } }

    expect(inertia).to render_component 'events/new'
    expect(inertia).to have_props(errors: { title: ["can't be blank"] })
  end
end
```

== Minitest

```ruby
class EventsTest < ActionDispatch::IntegrationTest
  test 'returns validation errors' do
    post events_path, params: { event: { title: '' } }

    assert_inertia_component 'events/new'
    assert_inertia_props errors: { title: ["can't be blank"] }
  end
end
```

:::

### Test redirects

After a [redirect](/guide/redirects), use `follow_redirect!` and assert the resulting Inertia response.

:::tabs key:tests

== RSpec

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

== Minitest

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

:::

### Test deferred props

[Deferred props](/guide/deferred-props) are excluded from the initial page load and fetched in a subsequent request.

:::tabs key:tests

== RSpec

```ruby
RSpec.describe '/events' do
  it 'defers expensive data' do
    get events_path

    expect(inertia).to have_deferred_props
    expect(inertia).to have_deferred_props(:analytics)
    expect(inertia).to have_deferred_props(:analytics, :statistics)

    # Check a specific group
    expect(inertia).to have_deferred_props(:other_data, group: :slow)

    expect(inertia.deferred_props[:default]).to include('analytics')
    expect(inertia.props[:analytics]).to be_nil
  end
end
```

== Minitest

```ruby
class EventsTest < ActionDispatch::IntegrationTest
  test 'defers expensive data' do
    get events_path

    assert_inertia_deferred_props
    assert_inertia_deferred_props :analytics
    assert_inertia_deferred_props :analytics, :statistics

    # Check a specific group
    assert_inertia_deferred_props :other_data, group: :slow

    assert_includes inertia.deferred_props[:default], 'analytics'
    assert_nil inertia.props[:analytics]
  end
end
```

:::

### Test partial reloads

Use `inertia_reload_only`, `inertia_reload_except`, and `inertia_load_deferred_props` to simulate [partial reloads](/guide/partial-reloads) and deferred prop loading.

:::tabs key:tests

== RSpec

```ruby
RSpec.describe '/events' do
  it 'supports partial reloads' do
    get events_path

    inertia_reload_only(:analytics, :statistics)
    expect(inertia.props[:analytics]).to be_present

    inertia_reload_except(:expensive_data)

    # Load deferred props by group
    inertia_load_deferred_props(:default)

    # Load all deferred props
    inertia_load_deferred_props
  end
end
```

== Minitest

```ruby
class EventsTest < ActionDispatch::IntegrationTest
  test 'supports partial reloads' do
    get events_path

    inertia_reload_only(:analytics, :statistics)
    assert_not_nil inertia.props[:analytics]

    inertia_reload_except(:expensive_data)

    # Load deferred props by group
    inertia_load_deferred_props(:default)

    # Load all deferred props
    inertia_load_deferred_props
  end
end
```

:::

## Configuration

### `evaluate_optional_props`

@available_since rails=3.18.0

By default, [optional](/guide/partial-reloads#optional-props) and [deferred](/guide/deferred-props) props are excluded on first load — just like in production. This means `inertia.props[:my_optional]` returns `nil` unless you simulate a partial reload.

To have these props evaluated on first load in tests, enable `evaluate_optional_props`:

:::tabs key:tests

== RSpec

```ruby
# spec/rails_helper.rb
require 'inertia_rails/rspec'

InertiaRails::Testing.evaluate_optional_props = true
```

== Minitest

```ruby
# test/test_helper.rb
require 'inertia_rails/minitest'

InertiaRails::Testing.evaluate_optional_props = true
```

:::

Optional and deferred props are then included in `inertia.props` on first load:

:::tabs key:tests

== RSpec

```ruby
get events_path

expect(inertia.props[:analytics]).to be_present
expect(inertia.props[:statistics]).to eq({ views: 100 })
```

== Minitest

```ruby
get events_path

assert_not_nil inertia.props[:analytics]
assert_equal({ views: 100 }, inertia.props[:statistics])
```

:::

You can also toggle this setting per-test:

:::tabs key:tests

== RSpec

```ruby
around do |example|
  InertiaRails::Testing.evaluate_optional_props = true
  example.run
ensure
  InertiaRails::Testing.evaluate_optional_props = false
end
```

== Minitest

```ruby
def test_optional_props
  InertiaRails::Testing.evaluate_optional_props = true
  get events_path
  assert_not_nil inertia.props[:analytics]
ensure
  InertiaRails::Testing.evaluate_optional_props = false
end
```

:::

::: warning
When `evaluate_optional_props` is enabled, deferred props will appear in `inertia.props` but will still be listed in `inertia.deferred_props`. Partial reload behaviour is unaffected — this setting only changes first-load behaviour.
:::
