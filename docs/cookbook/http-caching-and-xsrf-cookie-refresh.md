# HTTP caching and XSRF cookie refresh

By default, Inertia Rails rewrites the `XSRF-TOKEN` cookie on every protected request. Each rewrite emits a `Set-Cookie` header — including on otherwise cacheable `GET` responses and even on `304 Not Modified` responses. If your app relies on HTTP caching for Inertia pages, that header can quietly defeat it. This page explains why it happens and how to opt into a less aggressive refresh policy. For the broader caching picture, see the [caching guide](/guide/caching).

> [!NOTE]
> On Rails 8.2+ with the `:header_only` forgery protection strategy (the 8.2 default), none of this applies: authenticity tokens are never read, so the adapter skips the `XSRF-TOKEN` cookie entirely and no `Set-Cookie` is emitted at all. See [Header-Only CSRF Protection](/guide/csrf-protection#header-only-csrf-protection-rails-8-2). The refresh policies below matter only for token-based strategies.

## Symptom

The problem shows up in two places:

- **CDNs and shared caches.** Most shared caches refuse to cache responses that carry `Set-Cookie`. For example, Cloudflare either strips the header or [sets the cache status to `BYPASS`](https://developers.cloudflare.com/cache/concepts/cache-behavior/), depending on cache settings. `rack-cache`, Varnish, and Fastly behave similarly by default. If every response carries a fresh `XSRF-TOKEN`, your cacheable pages never get cached.
- **Browser conditional caching.** Apps using `fresh_when` / `stale?` expect reloads to settle into a clean `If-None-Match` / `304` loop. Repeated cookie writes on cacheable responses have been observed to prevent that, most notably in Safari/WebKit (Chrome and Firefox usually revalidate cookie-bearing responses correctly).

## Why it happens

The adapter refreshes the `XSRF-TOKEN` cookie in an `after_action` on every request where forgery protection is active, so Inertia's HTTP client can read it and send it back as an `X-XSRF-TOKEN` header.

Rails normally suppresses `Set-Cookie` when a cookie is written with its existing value — but that never applies here. Rails masks CSRF tokens with a random one-time pad on every call (a BREACH mitigation), so `form_authenticity_token` returns a _different_ string on every request even though the underlying token hasn't changed. The cookie jar sees a new value every time and emits `Set-Cookie` on every response, including `304`s.

Because the value is re-masked on every call, the only way to know whether the cookie actually needs a refresh is to unmask and compare it against the session token — which is exactly what the `:lazy` policy does when it can.

## The `:lazy` policy

To skip unnecessary rewrites on steady-state safe requests, opt into the `:lazy` policy:

```ruby
InertiaRails.configure do |config|
  config.xsrf_cookie_refresh = :lazy
end
```

You can also enable it for specific controllers only:

```ruby
class CachedPagesController < ApplicationController
  inertia_config xsrf_cookie_refresh: :lazy
end
```

Under `:lazy`, the adapter behaves as follows:

- `GET` / `HEAD` requests with no `XSRF-TOKEN` cookie: set the cookie, as before.
- `GET` / `HEAD` requests with an existing cookie, when the session or CSRF token is already loaded: validate the cookie against the session and refresh it only if it's stale.
- `GET` / `HEAD` requests with an existing cookie, when nothing has loaded the session: trust the cookie and skip the write (see the caveat below).
- Non-safe requests (`POST`, `PATCH`, and so on): always refresh, as before.

Conditionally cached pages take the validation path, not the trust path: `fresh_when` and `stale?` load the session (flash is part of the default ETag), so a stale cookie is detected and refreshed even on a `304` response.

## When this matters

This option matters most when all of the following are true:

- your app uses `fresh_when` / `stale?` on Inertia pages, or serves them through a CDN
- the route is a cacheable `GET`
- you expect reloads or revisits to produce `304`s or CDN cache hits

It usually does **not** matter for apps that rely only on Inertia prefetching or server-side caching.

## What this does not solve

This option only addresses `XSRF-TOKEN` churn.

Cookie-backed sessions are a separate source of `Set-Cookie` churn: the session cookie is re-encrypted on every response that touches the session, and `fresh_when` / `stale?` touch the session. If your app stores sessions in cookies, `:lazy` alone won't produce fully `Set-Cookie`-free `304`s — moving session storage to Redis or a database removes that second source.

The adapter also deliberately does _not_ load a lazy session just to validate an existing cookie: loading a cookie-backed session emits its own session `Set-Cookie`, which would reintroduce the exact churn this option removes.

## Caveat: stale cookies on session-less requests

On `GET` / `HEAD` requests where nothing loads the session — no Inertia render, no flash, no `fresh_when` — an existing cookie is trusted without validation. A stale cookie (for example, after a `secret_key_base` rotation) is not detected on those requests, so the next protected request fails with `InvalidAuthenticityToken`.

This failure is loud, never a silent CSRF bypass: the cookie is not a server-side validation input (the server checks the `X-XSRF-TOKEN` _header_ against the session). And it self-heals — any request that loads the session, including every rendered Inertia response, validates and refreshes the cookie.

## Security tradeoff

The tradeoff is compatibility, not reduced CSRF protection:

- Rails still validates CSRF tokens on all non-GET requests.
- Existing cookies are validated whenever validation is possible without loading the session solely for that check.
- Legitimate failures appear as `InvalidAuthenticityToken`, not as a silent bypass.

If you need every safe request to refresh the XSRF cookie from the current session state, keep the default `:always` policy.

> [!NOTE]
> Rails 8.2 introduces `protect_from_forgery using: :header_only`, which verifies requests with the `Sec-Fetch-Site` header instead of tokens. On apps using that strategy the `XSRF-TOKEN` cookie serves no purpose at all, and a policy to skip it entirely may be added in a future release. `:lazy` targets today's token-based apps, including Rails 8.2's `:header_or_legacy_token` upgrade path.
