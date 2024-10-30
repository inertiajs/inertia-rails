# Server-side setup

The first step when installing Inertia is to configure your server-side framework. Inertia maintains official server-side adapters for [Laravel](https://laravel.com) and [Ruby on Rails](https://rubyonrails.org). For other frameworks, please see the [community adapters](https://inertiajs.com/community-adapters).

> [!NOTE]
> For the official Laravel adapter instructions, please see the [official documentation](https://inertiajs.com/server-side-setup).

## Install dependencies

First, install the Inertia server-side adapter gem and add to the application's Gemfile by executing:

```bash
bundle add inertia_rails
```

## Rails generator

If you plan to use Vite as your frontend build tool, you can use the `inertia_rails-contrib` gem to install and set up Inertia in a Rails application. It automatically detects if the [Vite Rails](https://vite-ruby.netlify.app/guide/rails.html) gem is installed and will attempt to install it if not present.

To install and setup Inertia in a Rails application, execute the following command in the terminal:

```bash
bundle add inertia_rails-contrib
bin/rails generate inertia:install
```

This command will:

- Check for Vite Rails and install it if not present
- Ask if you want to use TypeScript
- Ask you to choose your preferred frontend framework (React, Vue, Svelte 4, or Svelte 5)
- Ask if you want to install Tailwind CSS
- Install necessary dependencies
- Set up the application to work with Inertia
- Copy example Inertia controller and views (can be skipped with the `--skip-example` option)

> [!NOTE]
> To use TypeScript with Svelte, you need to install `@inertiajs/svelte` version `1.3.0-beta.2` or higher. You can use the `--inertia-version` option to specify the version.

> [!NOTE]
> The `inertia_rails-contrib` gem doesn't include [Rails scaffold generators](/guide/responses#rails-generators) for TypeScript yet.

Example output:

```bash
$ bin/rails generate inertia:install
Installing Inertia's Rails adapter
Could not find a package.json file to install Inertia to.
Would you like to install Vite Ruby? (y/n) y
         run  bundle add vite_rails from "."
Vite Rails gem successfully installed
         run  bundle exec vite install from "."
Vite Rails successfully installed
Would you like to use TypeScript? (y/n) y
Adding TypeScript support
What framework do you want to use with Inertia? [react, vue, svelte4, svelte] (react)
         run  npm add @types/react @types/react-dom typescript --silent from "."
Would you like to install Tailwind CSS? (y/n) y
Installing Tailwind CSS
         run  npm add tailwindcss postcss autoprefixer @tailwindcss/forms @tailwindcss/typography @tailwindcss/container-queries --silent from "."
      create  tailwind.config.js
      create  postcss.config.js
      create  app/frontend/entrypoints/application.css
Adding Tailwind CSS to the application layout
      insert  app/views/layouts/application.html.erb
Adding Inertia's Rails adapter initializer
      create  config/initializers/inertia_rails.rb
Installing Inertia npm packages
         run  npm add @vitejs/plugin-react react react-dom --silent from "."
         run  npm add @inertiajs/react@latest --silent from "."
Adding Vite plugin for react
      insert  vite.config.ts
     prepend  vite.config.ts
Copying inertia.ts entrypoint
      create  app/frontend/entrypoints/inertia.ts
Adding inertia.ts script tag to the application layout
      insert  app/views/layouts/application.html.erb
Adding Vite React Refresh tag to the application layout
      insert  app/views/layouts/application.html.erb
        gsub  app/views/layouts/application.html.erb
Copying example Inertia controller
      create  app/controllers/inertia_example_controller.rb
Adding a route for the example Inertia controller
       route  get 'inertia-example', to: 'inertia_example#index'
Copying page assets
      create  app/frontend/pages/InertiaExample.module.css
      create  app/frontend/assets/react.svg
      create  app/frontend/assets/inertia.svg
      create  app/frontend/assets/vite_ruby.svg
      create  app/frontend/pages/InertiaExample.tsx
      create  tsconfig.json
      create  tsconfig.app.json
      create  tsconfig.node.json
      create  app/frontend/vite-env.d.ts
Copying bin/dev
      create  bin/dev
Inertia's Rails adapter successfully installed
```

With that done, you can now start the Rails server and the Vite development server (we recommend using [Overmind](https://github.com/DarthSim/overmind)):

```bash
bin/dev
```

And navigate to `http://localhost:3100/inertia-example` to see the example Inertia page.

That's it! You're all set up to start using Inertia in your Rails application. Check the guide on [creating pages](/guide/pages) to know more.

## Root template

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

    <%= inertia_headers %>

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

    <%= inertia_headers %>

    <%= stylesheet_pack_tag 'application' %>
    <%= javascript_pack_tag 'application', defer: true %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

:::

This template should include your assets, as well as the `yield` method to render the Inertia page. The `inertia_headers` method is used to include the Inertia headers in the response, it's required when [SSR](/guide/server-side-rendering.md) is enabled.

Inertia's adapter will use standard Rails layout inheritance, with `view/layouts/application.html.erb` as a default layout. If you would like to use a different default layout, you can change it using the `InertiaRails.configure`.

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.layout = 'my_inertia_layout'
end
```

# Creating responses

That's it, you're all ready to go server-side! Once you setup the [client-side](/guide/client-side-setup.md) framework, you can start start creating Inertia [pages](/guide/pages.md) and rendering them via [responses](/guide/responses.md).

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
