# Asset versioning

One common challenge when building single-page apps is refreshing site assets when they've been changed. Thankfully, Inertia makes this easy by optionally tracking the current version of your site assets. When an asset changes, Inertia will automatically make a full page visit instead of a XHR visit on the next request.

## Configuration!

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
