# Caching

Inertia Rails supports two complementary caching strategies: HTTP caching for full responses, and prop-level caching for expensive data. You can use them independently or together.

## HTTP Caching

Rails provides built-in HTTP caching via `stale?` and `fresh_when`. These work with Inertia responses, but require one adjustment: because the same URL returns HTML on the initial page load and JSON on subsequent Inertia visits, ETags must account for the request type.

### Differentiating ETags

Use the `etag` method in your controller to include `request.inertia?` in the ETag calculation:

```ruby
class ApplicationController < ActionController::Base
  etag { request.inertia? }
end
```

This ensures that HTML and JSON responses for the same URL produce different ETags, preventing the browser from serving a stale cached response in the wrong format.

### Using `stale?`

With the ETag differentiation in place, use `stale?` as you normally would in Rails:

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])

    if stale?(@post)
      render inertia: { post: @post.as_json }
    end
  end
end
```

When the post hasn't changed, Rails returns a `304 Not Modified` response and skips rendering entirely.

### Using `fresh_when`

For simpler cases where you don't need conditional logic:

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])
    fresh_when(@post)

    render inertia: { post: @post.as_json }
  end
end
```

## Prop-Level Caching

For caching individual props on the server side, see [Cached props](/guide/cached-props). Prop-level caching stores computed prop values in your Rails cache store, skipping expensive block evaluation on cache hits.

```ruby
class DashboardController < ApplicationController
  def index
    render inertia: {
      stats: InertiaRails.cache('dashboard_stats', expires_in: 1.hour) { Stats.compute },
      feed: InertiaRails.defer(cache: 'user_feed') { current_user.feed },
    }
  end
end
```
