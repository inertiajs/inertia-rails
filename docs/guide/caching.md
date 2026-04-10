# Caching

Inertia Rails offers several complementary strategies for avoiding redundant work. Each solves a different problem, and you can combine them.

## Choosing a Strategy

| Strategy                             | What it saves               | Where it lives          | Best for                                  |
| ------------------------------------ | --------------------------- | ----------------------- | ----------------------------------------- |
| [HTTP caching](#http-caching)        | Entire response render      | Browser / CDN           | Pages tied to a single record's freshness |
| [Cached props](#prop-level-caching)  | Block evaluation            | Server-side cache store | Expensive queries or computations         |
| [Once props](#once-props)            | Bandwidth and serialization | Client memory           | Large or rarely-changing shared data      |
| [SSR caching](#ssr-response-caching) | SSR render request          | Server-side cache store | Avoiding redundant Node.js SSR calls      |

In short: **cached props skip computing**, **once props skip sending**, **HTTP caching skips rendering**, and **SSR caching skips the SSR request**.

These strategies are independent. A prop can be both cached on the server and marked as once so the client doesn't re-request it. HTTP caching can wrap an entire response that contains cached props. SSR caching can be layered on top of any combination.

### Why only `defer` and `optional` support the `cache` option

The `cache` option is available on [deferred](/guide/deferred-props) and [optional](/guide/partial-reloads#lazy-data-evaluation) props because these represent data that is loaded on demand — caching their result avoids re-evaluating expensive blocks on repeated requests.

Other prop types don't need it:

- **Once props** already skip evaluation when the client has the data. If the computation itself is expensive, use `InertiaRails.cache` directly in the block.
- **Always props** are meant for cheap, frequently-changing data (flash messages, auth state). If the data is expensive enough to cache, it probably shouldn't be `always`.
- **Merge and scroll props** describe how the client handles the data, not how the server computes it. If the underlying data is expensive, wrap it with `InertiaRails.cache` and pass the result.

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

Prop-level caching stores computed values in your Rails cache store, skipping expensive block evaluation on cache hits. See the [Cached props](/guide/cached-props) guide for full details.

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

## Once Props

Once props are remembered by the client and excluded from subsequent responses. This saves bandwidth for data that rarely changes, such as shared navigation or role lists. See the [Once props](/guide/once-props) guide for full details.

```ruby
class ApplicationController < ActionController::Base
  inertia_share countries: InertiaRails.once { Country.all }
end
```

## SSR Response Caching

When SSR is enabled, each page load sends a request to the Node.js server. SSR caching stores these responses so identical page data is only rendered once. See [SSR response caching](/guide/server-side-rendering#ssr-response-caching) for full details.

```ruby
InertiaRails.configure do |config|
  config.ssr_cache = true
end
```
