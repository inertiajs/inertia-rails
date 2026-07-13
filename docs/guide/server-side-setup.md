# Server-Side Setup

The first step when installing Inertia is to configure your server-side framework.

> [!NOTE]
> For the official Laravel adapter instructions, please see the [official documentation](https://inertiajs.com/server-side-setup).

## Install Dependencies

First, install the Inertia server-side adapter gem and add to the application's Gemfile by executing:

```bash
bundle add inertia_rails
```

## Rails Generator

If you plan to use Vite as your frontend build tool, you can use the built-in generator to install and set up Inertia in a Rails application. It automatically detects if the [Vite Rails](https://vite-ruby.netlify.app/guide/rails.html) gem is installed and will attempt to install it if not present.

To install and setup Inertia in a Rails application, execute the following command in the terminal:

```bash
bin/rails generate inertia:install
```

This command will:

- Check for Vite Rails and install it if not present
- Ask if you want to use TypeScript
- Ask you to choose your preferred frontend framework (React, Vue, Svelte)
- Ask if you want to install Tailwind CSS
- Install necessary dependencies
- Set up the application to work with Inertia
- Copy example Inertia controller and views (can be skipped with the `--skip-example` option)

With that done, you can now start the Rails server and the Vite development server (we recommend using [Overmind](https://github.com/DarthSim/overmind)):

```bash
bin/dev
```

And navigate to `http://localhost:3100/inertia-example` to see the example Inertia page.

That's it! You're all set up to start using Inertia in your Rails application. Check the guide on [creating pages](/guide/pages) to know more.

## Root Template

If you decide not to use the generator, you can manually set up Inertia in your Rails application.

First, setup the root template that will be loaded on the first page visit. This will be used to load your site assets (CSS and JavaScript), and will also contain a root `<div>` to boot your JavaScript application in.

:::tabs key:builders
== Vite

```erb
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csp_meta_tag %>

    <%= inertia_ssr_head %>

    <%# If you want to use React add `vite_react_refresh_tag` %>
    <%= vite_client_tag %>
    <%= vite_javascript_tag 'application' %>
  </head>

  <body>
    <%= yield %>
  </body>
</html>
```

== Webpacker/Shakapacker

```erb
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csp_meta_tag %>

    <%= inertia_ssr_head %>

    <%= stylesheet_pack_tag 'application' %>
    <%= javascript_pack_tag 'application', defer: true %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

:::

This template should include your assets, as well as the `yield` method to render the Inertia page. The `inertia_ssr_head` method is used to include the Inertia headers in the response, it's required when [SSR](/guide/server-side-rendering.md) is enabled.

Inertia's adapter will use standard Rails layout inheritance, with `view/layouts/application.html.erb` as a default layout. If you would like to use a different default layout, you can change it using the `InertiaRails.configure`.

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.layout = 'my_inertia_layout'
end
```

# Creating Responses

That's it, you're all ready to go server-side! Once you setup the [client-side](/guide/client-side-setup.md) framework, you can start start creating Inertia [pages](/guide/pages.md) and rendering them via [responses](/guide/responses.md).

```ruby
class EventsController < ApplicationController
  def show
    event = Event.find(params[:id])

    render inertia: {
      event: event.as_json(
        only: [:id, :title, :start_date, :description]
      )
    }
  end
end
```
