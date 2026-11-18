# Responses

## Creating Responses

Creating an Inertia response is simple. By default, Inertia Rails follows convention over configuration: you pass the props (data) you wish to send to the page, and the component name is automatically inferred from the controller and action.

In the example below, we will pass a single prop (`user`) to the `users/show` page component.

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

### Using Instance Variables as Props

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

## Properties

To pass data from the server to your page components, you can use props. You can pass various types of values as props, including primitive types, hashes, arrays, Active Record objects, lambdas, and custom objects:

```ruby
class DashboardController < ApplicationController
  def index
    render inertia: {
      # Primitive values
      title: 'Dashboard',
      count: 42,
      active: true,

      # Hashes and arrays
      settings: { theme: 'dark', notifications: true },

      # Active Record models and relations
      event: Event.first,
      events: Event.all,

      # Objects that respond to `to_inertia`
      avatar: UserAvatar.new(current_user, size: 128),

      # Lambdas
      timestamp: -> { Time.current.to_i },
    }
  end
end
```

Active Record models, relations, and other Ruby objects are converted with `as_json` when Inertia serializes the response. Objects that respond to `to_inertia` are converted with that method instead, as described in [the next section](#the-to-inertia-method). Lambdas run only when the response includes the prop, which makes them useful for [partial reloads](/guide/partial-reloads#lazy-data-evaluation).

Integers outside JavaScript's safe range lose precision in the browser. You may preserve them as native `BigInt` values using [big integer support](/guide/big-integers).

## The `to_inertia` Method

@available_since rails=3.19.0

When passing props to your components, you may want to create custom classes that can transform themselves into the appropriate data format. Any object that responds to `to_inertia` can be a prop value. Inertia calls the method and sends its return value in place of the object.

```ruby
class UserAvatar
  def initialize(user, size: 64)
    @user = user
    @size = size
  end

  def to_inertia
    @user.avatar_url.presence ||
      "https://ui-avatars.com/api/?name=#{ERB::Util.url_encode(@user.name)}&size=#{@size}"
  end
end
```

Once defined, you can use this class directly as a prop value.

```ruby
class ProfilesController < ApplicationController
  def show
    user = User.find(params[:id])

    render inertia: {
      user: user.as_json(only: [:id, :name]),
      avatar: UserAvatar.new(user, size: 128),
    }
  end
end
```

Inertia also finds these objects inside nested hashes and arrays, and when a lambda or a prop type returns one. The `to_inertia` method may return a hash that contains lambdas and prop types. Inertia resolves them like any other props, including on partial reloads.

```ruby
class CourseProps
  def initialize(course)
    @course = course
  end

  def to_inertia
    course = @course

    {
      title: course.title,
      students: InertiaRails.optional { course.students.as_json(only: [:id, :name]) },
    }
  end
end
```

> [!WARNING]
> Inertia runs lambdas and prop type blocks in the controller's context, so an instance variable like `@course` inside the block reads the controller's variable. Copy the value to a local variable first, as in the example above.

Like a lambda, `to_inertia` runs only when the response includes the prop, so a partial reload that skips the prop doesn't call it.

The `to_inertia` method receives no arguments. It can't see the prop's key, the other props, or the request, so pass anything it needs to the constructor.

### Passing an Object as Props

@available_since rails=3.23.0

In some situations you may want to group related props together for reusability across different pages. You can pass an object that responds to `to_inertia` as the `props:` option. Its `to_inertia` method must return a hash, and each key becomes a prop.

```ruby
class UserPermissions
  def initialize(user)
    @user = user
  end

  def to_inertia
    {
      can_edit: @user.editor?,
      can_publish: @user.publisher?,
      is_admin: @user.admin?,
    }
  end
end
```

```ruby
class ProfilesController < ApplicationController
  def show
    render inertia: 'profiles/show', props: UserPermissions.new(current_user)
  end
end
```

Inertia merges [shared data](/guide/shared-data) with these props as usual. To combine the object with other props, merge its hash into a props hash:

```ruby
render inertia: {
  user: current_user.as_json(only: [:id, :name]),
  **UserPermissions.new(current_user).to_inertia,
}
```

## Root Template Data

There are situations where you may want to access your prop data in your ERB template. For example, you may want to add a meta description tag, Twitter card meta tags, or Facebook Open Graph meta tags.

Inertia Rails provides several view helpers for working with Inertia data in your templates:

### `inertia_page`

Returns the [page object](/guide/the-protocol#the-page-object) hash containing `component`, `props`, `url`, and other Inertia data. Use this to access page data in your root template.

```erb
# app/views/inertia.html.erb

<% content_for(:head) do %>
<meta name="twitter:title" content="<%= inertia_page[:props][:event][:title] %>">
<% end %>

<%= inertia_root %>
```

### `inertia_rendering?`

Returns `true` when the current request is rendering an Inertia response. This is useful for conditionally rendering content in shared layouts.

```erb
# app/views/layouts/application.html.erb

<% if inertia_rendering? %>
  <%= yield %>
<% else %>
  <div class="traditional-layout">
    <%= yield %>
  </div>
<% end %>
```

### `inertia_root`

Renders the root element for the Inertia app. This helper automatically respects the [`root_dom_id`](/guide/configuration#root-dom-id) and [`use_script_element_for_initial_page`](/guide/configuration#use-script-element-for-initial-page) configuration options.

```erb
<%= inertia_root %>
```

You can also pass a custom `id` or `page` object if needed:

```erb
<%= inertia_root(id: 'my-app', page: custom_page_object) %>
```

### `inertia_ssr_head`

Returns the SSR head content when [server-side rendering](/guide/server-side-rendering) is enabled. This should be included in your layout's `<head>` section to inject SSR-generated meta tags and other head elements.

```erb
# app/views/layouts/inertia.html.erb

<!DOCTYPE html>
<html>
  <head>
    <%= inertia_ssr_head %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

@available_since rails=3.23.0

Pass a block to render fallback head elements when the response isn't server-side rendered. When SSR is active, the `<Head>` component already provides these elements, so the block is skipped. Give fallback `<meta>` tags a `data-inertia` key, so the `<Head>` component replaces them instead of adding a duplicate.

```erb
<head>
  <%= inertia_ssr_head do %>
    <title>My App</title>
    <meta data-inertia="description" name="description" content="My application description">
  <% end %>
</head>
```

### `inertia_meta_tags`

Renders meta tags that were defined server-side using the `inertia_meta` configuration. This is useful for SEO when you want to manage meta tags from your Rails controllers. See the [Server-managed meta tags cookbook](/cookbook/server-managed-meta-tags) for a complete guide.

```erb
<head>
  <%= inertia_meta_tags %>
</head>
```

#### Default Title

@available_since rails=3.23.0 core=3.0.1

Pass `default_title:` to render a plain `<title>` when the page has no title of its own, for example on non-Inertia pages:

```erb
<head>
  <%= inertia_meta_tags(default_title: content_for(:title) || "My App") %>
</head>
```

### Passing Additional Data to the View

Sometimes you may want to provide data to the root template that will not be sent to your JavaScript page / component. This can be accomplished by passing the `view_data` option.

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

<%= inertia_root %>
```

## Rails Generators

Inertia Rails provides a number of generators to help you get started with Inertia in your Rails application. You can generate controllers or use scaffolds to create a new resource with Inertia responses.

### Scaffold Generator

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

#### Tailwind CSS Integration

Inertia Rails tries to detect the presence of Tailwind CSS in the application and generate the templates accordingly. If you want to specify templates type, use the `--inertia-templates` option:

- `inertia_templates` - default
- `inertia_tw_templates` - Tailwind CSS

### Controller Generator

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

### Customizing the Generator Templates

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

## Maximum Response Size

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

## Inertia Responses and `respond_to`

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
