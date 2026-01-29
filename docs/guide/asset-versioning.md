# Asset versioning

One common challenge when building single-page apps is refreshing site assets when they've been changed. Thankfully, Inertia makes this easy by optionally tracking the current version of your site assets. When an asset changes, Inertia will automatically make a full page visit instead of a XHR visit on the next request.

## Configuration

To enable automatic asset refreshing, you need to tell Inertia the current version of your assets using the `InertiaRails.configure` method and setting the `config.version` property. This can be any arbitrary string (letters, numbers, or a file hash), as long as it changes when your assets have been updated.

```ruby
InertiaRails.configure do |config|
  config.version = ViteRuby.digest # or any other versioning method
end

# You can also use lazy evaluation
InertiaRails.configure do |config|
  config.version = lambda { ViteRuby.digest }
end
```

## Cache busting

Asset refreshing in Inertia works on the assumption that a hard page visit will trigger your assets to reload. However, Inertia doesn't actually do anything to force this. Typically this is done with some form of cache busting. For example, appending a version query parameter to the end of your asset URLs.

## Manual refreshing

If you want to take asset refreshing into your own control, you can set the version to a fixed value. This disables Inertia's automatic asset versioning.

For example, if you want to notify users when a new version of your frontend is available, you can still expose the actual asset version to the frontend by including it as [shared data](/guide/shared-data).

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  # Disable automatic asset versioning
  config.version = nil
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  inertia_share version: -> { ViteRuby.digest }
end
```

On the frontend, you can watch the `version` property and show a notification when a new version is detected.
