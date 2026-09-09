# Testing

There are many different ways to test an Inertia application. This page provides a quick overview of the tools available.

## End-to-end Tests

One popular approach to testing your JavaScript page components is to use an end-to-end testing tool like [Capybara](https://github.com/teamcapybara/capybara) (the foundation of Rails system tests) or [Cypress](https://www.cypress.io/). These are browser automation tools that allow you to run real simulations of your app in the browser. These tests are known to be slower; however, since they test your application at the same layer as your end users, they can provide a lot of confidence that your app is working correctly. And, since these tests are run in the browser, your JavaScript code is actually executed and tested as well.

### Capybara and the JavaScript driver

Capybara's default `:rack_test` driver does not execute JavaScript. Since every Inertia page is rendered by JavaScript, this driver never mounts your app. Without SSR the page body stays an empty `<div id="app">`, so tests fail with `Capybara::ElementNotFound` on their first interaction. With SSR enabled the failure is subtler: the server-rendered markup is present, so Capybara finds the elements, but the Inertia client never mounts to handle them. A `<Link>` with a non-GET `method` renders as a plain `<button type="button">` that does nothing when clicked, and the `<Form>` component renders a native `<form>` whose `method` attribute holds the literal verb — so a `post` form still issues a real `POST`, but `patch`, `put`, and `delete` forms fall back to `GET` (an HTML form only understands `get` and `post`). Either way the interaction bypasses Inertia, and assertions fail in confusing ways instead of raising a clear error.

To test an Inertia app with Capybara, use a JavaScript-capable driver such as [Cuprite](https://github.com/rubycdp/cuprite) (headless Chrome via CDP, no chromedriver needed) or Selenium:

```ruby
# Gemfile
group :test do
  gem 'capybara'
  gem 'cuprite'
end
```

> [!NOTE]
> Cuprite drives your locally installed Chrome or Chromium, so make sure one is available on the machine running the tests, including CI. Freshly generated Rails apps already include `capybara` and `selenium-webdriver` in the `:test` group, so `cuprite` is usually the only new gem you need to add.

:::tabs key:tests

== RSpec

System specs require [rspec-rails](https://github.com/rspec/rspec-rails) to be installed and configured first.

```ruby
# spec/rails_helper.rb (or a file in spec/support)
require 'capybara/cuprite'

Capybara.javascript_driver = :cuprite

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :cuprite
  end
end
```

== Minitest

```ruby
# test/application_system_test_case.rb
require 'test_helper'
require 'capybara/cuprite'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite
end
```

:::

With the driver in place, system tests (in `test/system/` or `spec/system/`) interact with Inertia pages the same way they do with classic Rails views:

```ruby
# test/system/posts_test.rb
test 'creates a post' do
  visit posts_url
  click_on 'New post'

  fill_in 'Content', with: 'Hello Inertia'
  click_on 'Create Post'

  assert_text 'Post was successfully created'
end
```

A few things to keep in mind:

- Vite must serve or build assets for the test environment. The default `config/vite.json` sets `autoBuild: true` for the test environment, which builds assets on demand. If you disabled it, run `RAILS_ENV=test bin/vite build` before the suite — otherwise the browser loads a page without JavaScript and you are back to the empty-shell symptom.
- `<Link>` components with a non-GET `method` render as `<button>` elements, not `<a>` tags. Use `click_on` or `click_button` to interact with them — `click_link` won't find them.
- Capybara's waiting matchers (`assert_text`, `have_text`) automatically wait for asynchronous Inertia visits to finish. Assert on visible page changes before asserting on side effects like database state.

## Client-Side Unit Tests

Another approach to testing your page components is using a client-side unit testing framework, such as [Vitest](https://vitest.dev/), [Jest](https://jestjs.io/), or [Mocha](https://mochajs.org/). This approach allows you to test your JavaScript page components in isolation using Node.js.

## Endpoint Tests

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

## Common Testing Tasks

### Test Flash Messages

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

### Test Validation Errors

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

### Test Redirects

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

### Test Deferred Props

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

### Test Partial Reloads

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
