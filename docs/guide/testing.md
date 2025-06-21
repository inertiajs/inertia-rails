# Testing

There are many different ways to test an Inertia.js app. This page provides a quick overview of the tools available.

## End-to-end tests

One popular approach to testing your JavaScript page components, is to use an end-to-end testing tool like [Capybara](https://github.com/teamcapybara/capybara) or [Cypress](https://www.cypress.io). These are browser automation tools that allow you to run real simulations of your app in the browser. These tests are known to be slower, and sometimes brittle, but since they test your application at the same layer as your end users, they can provide a lot of confidence that your app is working correctly. And, since these tests are run in the browser your JavaScript code is actually executed and tested as well.

## Client-side unit tests

Another approach to testing your page components is using a client-side unit testing framework, such as [Vitest](https://vitest.dev), [Jest](https://jestjs.io) or [Mocha](https://mochajs.org). This approach allows you to test your JavaScript page components in isolation using Node.js.

## Endpoint tests

In addition to testing your JavaScript page components, you'll also want to test the Inertia responses that come back from your server-side framework. A popular approach to doing this is using endpoint tests, where you make requests to your application and examine the responses.

If you're using RSpec, Inertia Rails comes with some nice test helpers to make things simple.

To use these helpers, just add the following require statement to your `spec/rails_helper.rb`

```ruby
require 'inertia_rails/rspec'
```

And in any test you want to use the inertia helpers, add the `:inertia` flag to the block.

```ruby
# spec/requests/events_spec.rb
RSpec.describe "/events", inertia: true do
  describe '#index' do
    # ...
  end
end
```

### Assertions

Inertia Rails provides several RSpec matchers for testing Inertia responses. You can use methods like `expect_inertia`, `render_component`, `have_exact_props`, `include_props`, `have_exact_view_data`, and `include_view_data` to test your Inertia responses.

```ruby
# spec/requests/events_spec.rb
RSpec.describe '/events', inertia: true do
  describe '#index' do
    let!(:event) { Event.create!(title: 'Foo', start_date: '2024-02-21', description: 'Foo bar') }

    it "renders inertia component" do
      get events_path

      # check the component
      expect(inertia).to render_component 'Event/Index'
      # or
      expect_inertia.to render_component 'Event/Index'
      # same as above
      expect(inertia.component).to eq 'Event/Index'

      # props (including shared props)
      expect(inertia).to have_exact_props({title: 'Foo', description: 'Foo bar'})
      expect(inertia).to include_props({title: 'Foo'})

      # access props
      expect(inertia.props[:title]).to eq 'Foo'

      # view data
      expect(inertia).to have_exact_view_data({meta: 'Foo bar'})
      expect(inertia).to include_view_data({meta: 'Foo bar'})

      # access view data
      expect(inertia.view_data[:meta]).to eq 'Foo bar'
    end
  end
end
```
