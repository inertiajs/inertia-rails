# Responses

## Creating responses

Creating an Inertia response is simple. By default, Inertia Rails follows convention over configuration: you simply pass the props (data) you wish to send to the page, and the component name is automatically inferred from the controller and action.

```ruby
class UsersController < ApplicationController
  def show
    user = User.find(params[:id])
    render inertia: { user: } # Renders '../users/show.jsx|vue|svelte'
  end
end
```

Within Rails applications, the `UsersController#show` action would typically correspond to the file located at `app/frontend/pages/users/show.(jsx|vue|svelte)`.

> [!WARNING]
> To ensure that pages load quickly, only return the minimum data required for the page. Also, be aware that **all data returned from the controllers will be visible client-side**, so be sure to omit sensitive information.

### Customizing the Component Path

While the default convention works for most cases, you may need to render a specific component or change how component paths are resolved globally.

#### Explicit Component Names

If you wish to render a component that does not match the current controller action, you can explicitly provide the name of the [JavaScript page component](/guide/pages) followed by the props hash.

```ruby
class EventsController < ApplicationController
  def my_event
    event = Event.find(params[:id])

    render inertia: 'events/show', props: {
      event: event.as_json(
        only: [:id, :title, :start_date, :description]
      )
    }
  end
end
```

#### Custom Path Resolver

If the default automatic path resolution does not match your project's conventions, you can define a custom resolution method via the `component_path_resolver` config value.

The value should be callable and will receive the `path` and `action` parameters, returning a string component path.

```ruby
inertia_config(
  component_path_resolver: ->(path:, action:) do
    "storefront/#{path.camelize}/#{action.camelize}"
  end
)
```

### Using instance variables as props

For convenience, Inertia can automatically pass your controller's instance variables to the page component as props. To enable this behavior, invoke the `use_inertia_instance_props` method within your controller or a base controller.

```ruby
class EventsController < ApplicationController
  use_inertia_instance_props

  def index
    @events = Event.all

    render inertia: 'events/index'
  end
end
```

In this example, the `@events` instance variable is automatically included in the response as the `events` prop.

Please note that if you manually provide a props hash in your render call, the instance variables feature is disabled for that specific response.

> [!WARNING]
> Security and Performance Risk
>
> When enabled, this feature serializes all instance variables present in the controller at the time of rendering. This includes:
>
> - Variables set by `before_action` filters (e.g., `@current_user`, `@breadcrumbs`) called **after** `use_inertia_instance_props`.
> - Memoized variables (often used for caching internal state, e.g., `@_cached_result`).
> - Variables intended only for server-side logic.
>
> This creates a high risk of accidentally leaking sensitive data or internal implementation details to the client. It can also negatively impact performance by serializing unnecessary heavy objects. We recommend being explicit with your props whenever possible.

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

  render inertia: { event: }, view_data: { meta: event.meta }
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

Use the `inertia:scaffold` generator to create a resource with Inertia responses. Execute the following command in the terminal:

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
      create      app/frontend/pages/posts
      create      app/frontend/pages/posts/index.svelte
      create      app/frontend/pages/posts/edit.svelte
      create      app/frontend/pages/posts/show.svelte
      create      app/frontend/pages/posts/new.svelte
      create      app/frontend/pages/posts/form.svelte
      create      app/frontend/pages/posts/post.svelte
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

Use the `inertia:controller` generator to create a controller with an Inertia response. Execute the following command in the terminal:

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
      create    app/frontend/pages/pages
      create    app/frontend/pages/pages/welcome.jsx
      create    app/frontend/pages/pages/next_steps.jsx
```

### Customizing the generator templates

Rails generators allow templates customization. You can create custom template files in your application to override the default templates used by the generators. For example, to customize the controller generator view template for React, create a file at the path `lib/templates/inertia_templates/controller/react/view.jsx.tt`:

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

For example, [Firefox](https://developer.mozilla.org/en-US/docs/Web/API/History/pushState) has a size limit of 16 MiB and throws a `NS_ERROR_ILLEGAL_VALUE` error if you exceed this limit. Typically, this is much more data than you'll ever practically need when building applications.

## Detecting Inertia Requests

Controllers can determine if a request was made via Inertia:

```ruby
def some_action
  if request.inertia?
  # This is an Inertia request
  end

  if request.inertia_partial?
  # This is a partial Inertia request
  end
end
```

## Inertia responses and `respond_to`

Inertia responses always operate as a `:html` response type. This means that you can use the `respond_to` method to handle JSON requests differently, while still returning Inertia responses:

```ruby
def some_action
  respond_to do |format|
    format.html do
      render inertia: { data: 'value' }
    end

    format.json do
      render json: { message: 'This is a JSON response' }
    end
  end
end
```
