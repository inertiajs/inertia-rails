# Responses

## Creating responses

Creating an Inertia response is simple. To get started, just use the `inertia` renderer in your controller methods, providing both the name of the [JavaScript page component](/guide/pages.md) that you wish to render, as well as any props (data) for the page.

```ruby
class EventsController < ApplicationController
  def show
    event = Event.find(params[:id])

    render inertia: 'Event/Show', props: {
      event: event.as_json(
        only: [:id, :title, :start_date, :description]
      )
    }
  end
end
```

Within Rails applications, the `Event/Show` page would typically correspond to the file located at `app/frontend/pages/Event/Show.(jsx|vue|svelte)`.

> [!WARNING]
> To ensure that pages load quickly, only return the minimum data required for the page. Also, be aware that **all data returned from the controllers will be visible client-side**, so be sure to omit sensitive information.

### Using instance variables as props

Inertia enables the automatic passing of instance variables as props. This can be achieved by invoking the `use_inertia_instance_props` function in a controller or in a base controller from which other controllers inherit.

```ruby
class EventsController < ApplicationController
  use_inertia_instance_props

  def index
    @events = Event.all

    render inertia: 'Events/Index'
  end
end
```

This action automatically passes the `@events` instance variable as the `events` prop to the `Events/Index` page component.

> [!NOTE]
> Manually providing any props for a response disables the instance props feature for that specific response.

> [!NOTE]
> Instance props are only included if they are defined **after** the `use_inertia_instance_props` call, hence the order of `before_action` callbacks is crucial.

### Automatically determine component name

Rails conventions can be used to automatically render the correct page component by invoking `render inertia: true`:

```ruby
class EventsController < ApplicationController
  use_inertia_instance_props

  def index
    @events = Event.all

    render inertia: true
  end
end
```

This renders the `app/frontend/pages/events/index.(jsx|vue|svelte)` page component and passes the `@events` instance variable as the `events` prop.

Setting the `default_render` configuration value to `true` establishes this as the default behavior:

```ruby
InertiaRails.configure do |config|
  config.default_render = true
end
```

```ruby
class EventsController < ApplicationController
  use_inertia_instance_props

  def index
    @events = Event.all
  end
end
```

With this configuration, the `app/frontend/pages/events/index.(jsx|vue|svelte)` page component is rendered automatically, passing the `@events` instance variable as the `events` prop.

## Root template data

There are situations where you may want to access your prop data in your ERB template. For example, you may want to add a meta description tag, Twitter card meta tags, or Facebook Open Graph meta tags. You can access this data via the `page` method.

```erb
# app/views/inertia.html.erb

<% content_for(:head) do %>
<meta name="twitter:title" content="<%= page["props"]["event"].title %>">
<% end %>

<div id="app" data-page="<%= page.to_json %>"></div>
```

Sometimes you may even want to provide data to the root template that will not be sent to your JavaScript page / component. This can be accomplished by passing the `view_data` option.

```ruby
def show
  event = Event.find(params[:id])

  render inertia: 'Event', props: { event: }, view_data: { meta: event.meta }
end
```

You can then access this variable like a regular local variable.

```erb
# app/views/inertia.html.erb

<% content_for(:head) do %>
<meta
  name="description"
  content="<%= local_assigns.fetch(:meta, "Default description") %>">
<% end %>

<div id="app" data-page="<%= page.to_json %>"></div>
```

## Rails generators

Inertia Rails provides a number of generators to help you get started with Inertia in your Rails application. You can generate controllers or use scaffolds to create a new resource with Inertia responses.

### Scaffold generator

To create a resource with Inertia responses, execute the following command in the terminal:

```bash
bin/rails generate inertia:scaffold ModelName field1:type field2:type
```

Example output:

```bash
$ bin/rails generate inertia:scaffold Post title:string body:text
      invoke  active_record
      create    db/migrate/20240611123952_create_posts.rb
      create    app/models/post.rb
      invoke    test_unit
      create      test/models/post_test.rb
      create      test/fixtures/posts.yml
      invoke  resource_route
       route    resources :posts
      invoke  scaffold_controller
      create    app/controllers/posts_controller.rb
      invoke    inertia_templates
      create      app/frontend/pages/Post
      create      app/frontend/pages/Post/Index.svelte
      create      app/frontend/pages/Post/Edit.svelte
      create      app/frontend/pages/Post/Show.svelte
      create      app/frontend/pages/Post/New.svelte
      create      app/frontend/pages/Post/Form.svelte
      create      app/frontend/pages/Post/Post.svelte
      invoke    resource_route
      invoke    test_unit
      create      test/controllers/posts_controller_test.rb
      create      test/system/posts_test.rb
      invoke    helper
      create      app/helpers/posts_helper.rb
      invoke      test_unit
```

#### Tailwind CSS integration

Inertia Rails tries to detect the presence of Tailwind CSS in the application and generate the templates accordingly. If you want to specify templates type, use the `--inertia-templates` option:

- `inertia_templates` - default
- `inertia_tw_templates` - Tailwind CSS

### Controller generator

To create a controller with an Inertia response, execute the following command in the terminal:

```bash
bin/rails generate inertia:controller ControllerName action1 action2
```

Example output:

```bash
$ bin/rails generate inertia:controller pages welcome next_steps
      create  app/controllers/pages_controller.rb
       route  get 'pages/welcome'
              get 'pages/next_steps'
      invoke  test_unit
      create    test/controllers/pages_controller_test.rb
      invoke  helper
      create    app/helpers/pages_helper.rb
      invoke    test_unit
      invoke  inertia_templates
      create    app/frontend/pages/Pages
      create    app/frontend/pages/Pages/Welcome.jsx
      create    app/frontend/pages/Pages/NextSteps.jsx
```

### Customizing the generator templates

Rails generators allow templates customization. For example, to customize the controller generator view template, create a file `lib/templates/inertia_templates/controller/react/view.jsx.tt`:

```jsx
export default function <%= @action.camelize %>() {
  return (
    <h1>Hello from my new default template</h1>
  );
}
```

You can find the default templates in the gem's source code:

- [Default controller generator templates](https://github.com/inertiajs/inertia-rails/tree/master/lib/generators/inertia_templates/controller/templates)
- [Default scaffold generator templates](https://github.com/inertiajs/inertia-rails/tree/master/lib/generators/inertia_templates/scaffold/templates)
- [Tailwind controller generator templates](https://github.com/inertiajs/inertia-rails/tree/master/lib/generators/inertia_tw_templates/controller/templates)
- [Tailwind scaffold generator templates](https://github.com/inertiajs/inertia-rails/tree/master/lib/generators/inertia_tw_templates/scaffold/templates)

> [!TIP]
> You can also replace the whole generator with your own implementation. See the [Rails documentation](https://guides.rubyonrails.org/generators.html#overriding-rails-generators) for more information.

## Maximum response size

To enable client-side history navigation, all Inertia server responses are stored in the browser's history state. However, keep in mind that some browsers impose a size limit on how much data can be saved within the history state.

For example, [Firefox](https://developer.mozilla.org/en-US/docs/Web/API/History/pushState) has a size limit of 640k characters and throws a `NS_ERROR_ILLEGAL_VALUE` error if you exceed this limit. Typically, this is much more data than you'll ever practically need when building applications.
