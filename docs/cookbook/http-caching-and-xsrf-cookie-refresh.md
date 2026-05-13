# HTTP Caching and XSRF Cookie Refresh

If your Rails app uses browser HTTP conditional caching (`ETag` / `Last-Modified` -> `304 Not Modified`) on Inertia pages, Safari/WebKit may keep returning `200 OK` on normal page reloads even though your controller code looks correct.

## Symptom

Typical Safari/WebKit symptom:

- a page returns `ETag` / `Last-Modified`
- repeated browser reloads still return `200`
- the browser does not settle into a clean `If-None-Match` / `304` loop

This can show up first on authenticated pages with `fresh_when` or `stale?`. It is not necessarily a general browser behavior; Chrome and Firefox can revalidate the same cookie-bearing response correctly.

## Why It Happens

The Rails adapter currently writes the `XSRF-TOKEN` cookie on every protected request:

```ruby
after_action do
  cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
end
```

That behavior is convenient because Inertia's HTTP client can read the `XSRF-TOKEN` cookie and send it back as `X-XSRF-TOKEN`.

However, some applications also depend on browser HTTP revalidation for conditionally cacheable GET pages. `Set-Cookie` does not make a response uncacheable by itself, and some browsers revalidate these responses correctly. In Safari/WebKit, repeatedly rewriting cookies on an otherwise cacheable HTML response can still prevent normal reloads from settling into the expected conditional request flow.

## Supported Adapter Configuration

If you want to reduce XSRF cookie churn on steady-state safe requests, you can opt into a less aggressive policy:

```ruby
InertiaRails.configure do |config|
  config.xsrf_cookie_refresh = :lazy
end
```

That changes the adapter behavior to:

- `GET` / `HEAD`: only set `XSRF-TOKEN` if the cookie is missing
- `GET` / `HEAD` requests that have already loaded the session or CSRF token: validate an existing `XSRF-TOKEN` cookie and refresh it if it no longer matches the current session
- non-safe requests: continue refreshing `XSRF-TOKEN` on every protected request

You may also enable this only for specific controllers:

```ruby
class CachedPagesController < ApplicationController
  inertia_config xsrf_cookie_refresh: :lazy
end
```

## When This Matters

This issue matters most when all of the following are true:

- your app uses `fresh_when` / `stale?`
- the route is a cacheable `GET`
- you expect browser reloads or revisits to return `304`
- your app is sensitive to repeated `Set-Cookie` writes on those responses
- you have observed the issue in Safari/WebKit or another browser environment

It usually does **not** matter for apps that rely only on Inertia prefetching or only on server-side caching.

## What This Does Not Solve

This option only addresses `XSRF-TOKEN` churn.

Some authenticated applications may also rewrite Rails session cookies on cacheable `GET` requests. This is common with cookie-backed sessions, where session data is stored in the browser cookie. If that is happening, `xsrf_cookie_refresh = :lazy` alone may not be enough to produce clean `304` revalidation behavior. Moving session storage off browser cookies, for example to Redis or a database, can reduce that separate source of `Set-Cookie` churn.

The adapter does not load the session only to validate an existing XSRF cookie on otherwise steady-state safe requests. Loading a cookie-backed session can itself cause Rails to emit a session `Set-Cookie` header, which would reintroduce the same browser revalidation problem this option is meant to reduce.

## Security Tradeoff

The tradeoff is usually compatibility, not reduced CSRF protection.

Even if an app chooses to refresh the `XSRF-TOKEN` cookie less aggressively:

- Rails still validates CSRF tokens on non-GET requests
- existing XSRF cookies are validated before the adapter skips refresh on `GET` / `HEAD` when validation can happen without loading the session only for that check
- apps may still emit `csrf_meta_tags`
- legitimate failures are more likely to appear as `InvalidAuthenticityToken` than as silent CSRF bypass

If you need every safe request to refresh the XSRF cookie from the current session state, keep the default `:always` policy.
