# Cached Props

@available_since rails=master

Cached props use your server-side cache store to avoid recomputing expensive data on every request. When the cache is warm, the block is never evaluated — Inertia serves the pre-serialized JSON directly.

> [!NOTE]
> To understand when to use cached props vs once props vs HTTP caching, see the [Caching](/guide/caching) guide.

## Creating Cached Props

To create a cached prop, use the `InertiaRails.cache` method. This method requires a cache key and a block that returns the prop data.

```ruby
class DashboardController < ApplicationController
  def index
    render inertia: {
      stats: InertiaRails.cache('dashboard_stats') { Stats.compute },
    }
  end
end
```

On the first request, the block is evaluated, serialized to JSON, and written to the cache. Subsequent requests serve the cached JSON without evaluating the block.

## Cache Keys

Cache keys determine when cached data is invalidated. Inertia supports several key formats.

### String Keys

The simplest form — a static string:

```ruby
InertiaRails.cache('sidebar_nav') { NavigationItem.tree }
```

### Active Record Objects

Pass an Active Record object to derive the key from `cache_key_with_version`. The cache is automatically invalidated when the record is updated:

```ruby
InertiaRails.cache(@post) { PostSerializer.render(@post) }
# Cache key: "inertia_rails/posts/1-20260410120000"
```

### Array Keys

Pass an array to build a composite key:

```ruby
InertiaRails.cache(['stats', current_user.id]) { Stats.for(current_user) }
# Cache key: "inertia_rails/stats/42"
```

## Cache Options

You can pass `expires_in` and `race_condition_ttl` options to control cache behavior:

```ruby
InertiaRails.cache('stats', expires_in: 1.hour) { Stats.compute }

InertiaRails.cache('stats', expires_in: 1.hour, race_condition_ttl: 10.seconds) { Stats.compute }
```

## Combining with Other Prop Types

The `cache` option can be passed to [deferred](/guide/deferred-props) and [optional](/guide/partial-reloads#lazy-data-evaluation) props:

```ruby
class DashboardController < ApplicationController
  def index
    render inertia: {
      # Deferred prop with caching
      feed: InertiaRails.defer(cache: 'user_feed', group: 'feed') { current_user.feed },

      # Optional prop with caching
      categories: InertiaRails.optional(cache: @team) { @team.categories },
    }
  end
end
```

The `cache` option accepts the same key formats as `InertiaRails.cache`: strings, Active Record objects, arrays, and hashes with options.

```ruby
InertiaRails.defer(cache: { key: 'feed', expires_in: 5.minutes }) { current_user.feed }
```

## Cache Store

By default, Inertia uses `Rails.cache`. You can configure a different store via the [`cache_store`](/guide/configuration#cache_store) option. All cached prop keys are automatically prefixed with `inertia_rails/` to avoid collisions.
