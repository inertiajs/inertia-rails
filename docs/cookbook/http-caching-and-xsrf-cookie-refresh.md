# HTTP Caching and XSRF Cookie Refresh

If your Rails app uses HTTP conditional caching (`ETag` / `Last-Modified` -> `304 Not Modified`) on Inertia pages, you may notice that browser revalidation does not work as expected even though your controller code looks correct.

## Symptom

Typical symptom:

- a page returns `ETag` / `Last-Modified`
- repeated browser reloads still return `200`
- the browser does not settle into a clean `If-None-Match` / `304` loop

This often shows up first on authenticated pages with `fresh_when` or `stale?`.

## Why It Happens

The Rails adapter currently writes the `XSRF-TOKEN` cookie on every request:

```ruby
after_action do
  cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
end
```

That behavior is convenient because Inertia's HTTP client can read the `XSRF-TOKEN` cookie and send it back as `X-XSRF-TOKEN`.

However, some applications also depend on browser HTTP revalidation for cacheable GET pages. In those apps, rewriting cookies on every response can make browser revalidation less effective in practice because the response keeps changing at the header/cookie layer even when the page data itself has not changed.

## Supported Adapter Configuration

If you want to reduce XSRF cookie churn on steady-state safe requests, you can opt into a less aggressive policy:

```ruby
InertiaRails.configure do |config|
  config.xsrf_cookie_refresh = :when_needed
end
```

That changes the adapter behavior to:

- `GET` / `HEAD`: only set `XSRF-TOKEN` if the cookie is missing
- non-safe requests: continue refreshing `XSRF-TOKEN` on every protected request

You may also enable this only for specific controllers:

```ruby
class CachedPagesController < ApplicationController
  inertia_config xsrf_cookie_refresh: :when_needed
end
```

## When This Matters

This issue matters most when all of the following are true:

- your app uses `fresh_when` / `stale?`
- the route is a cacheable `GET`
- you expect browser reloads or revisits to return `304`
- your app is sensitive to repeated `Set-Cookie` writes on those responses

It usually does **not** matter for apps that rely only on Inertia prefetching or only on server-side caching.

## What This Does Not Solve

This option only addresses `XSRF-TOKEN` churn.

Some authenticated applications may also rewrite session cookies on cacheable `GET` requests. If that is happening, `xsrf_cookie_refresh = :when_needed` alone may not be enough to produce clean `304` revalidation behavior.

## Security Tradeoff

The tradeoff is usually compatibility, not reduced CSRF protection.

Even if an app chooses to refresh the `XSRF-TOKEN` cookie less aggressively:

- Rails still validates CSRF tokens on non-GET requests
- apps may still emit `csrf_meta_tags`
- legitimate failures are more likely to appear as `InvalidAuthenticityToken` than as silent CSRF bypass

The main risk is stale token synchronization after some session-rotation flows, not weakened forgery protection.
