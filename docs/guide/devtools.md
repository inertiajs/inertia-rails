# DevTools

@available_since rails=master core=3.6.0

[Inertia DevTools](https://inertiajs.com/docs/v3/advanced/devtools) is a Chrome extension that records every Inertia request your app makes and shows you its props, headers, route, and merged page state. Inertia Rails implements the server half of the [DevTools protocol](https://inertiajs.com/docs/v3/advanced/devtools-protocol), so recording works with no setup in development.

## Installation

Install the [Chrome extension](https://chromewebstore.google.com/detail/inertiajs-devtools/cbaffpghpcbmgbnlpamegieokkpdlnih), then enable the client-side integrations in `createInertiaApp`:

```js
createInertiaApp({
  // ...
  dev: import.meta.env.DEV,
})
```

Open Chrome DevTools on your app and pick the **Inertia** panel.

## What gets recorded

Every response is recorded, whether or not it is an Inertia response, and stamped with an `X-Inertia-Devtools-Id` header. Successful initial Inertia HTML responses also get a `<script data-inertia-devtools-id>` tag injected before `</body>` so the extension can find the entry before any XHR happens. Responses your app gave a validator (`fresh_when`, `stale?`) are left alone, since rewriting the body under a stale `ETag` would break conditional GET; those entries are still discoverable through the response header.

Requests rendered by Rails exception handling are recorded with their final status and stamped with the same header. If exceptions are configured to propagate instead, DevTools retains a synthetic 500 entry, but there is no response to stamp.

For Inertia renders, the entry also carries:

- **Props** — every prop keyed by its dot path, badged with its type (`always`, `optional`, `defer`, `merge`, `scroll`, `once`), its defer group, merge direction, and whether it came from `inertia_share`.
- **Editor links** — the file and line of the `render inertia:` call (or `inertia` route definition), of the `inertia_share` block each shared prop came from, and of the controller action.
- **Route** — the matched route name, URI pattern, and `Controller#action`.
- **Page** — the full page object the client received.

Deferred and optional props are skipped before resolution on a first load, so they show up on the request that actually delivers them, not on the initial one.

## Enabling and disabling

Recording is on in development and off everywhere else. Set `config.devtools` (or the `INERTIA_DEVTOOLS_ENABLED` environment variable) to override:

```ruby
InertiaRails.configure do |config|
  config.devtools = true
end
```

Unlike most options, the whole `devtools_*` family is read globally rather than per controller — recording runs in middleware and the read API runs outside any controller, so `inertia_config` rejects these options instead of silently ignoring an override. While devtools is off, the `/_inertia/devtools` paths are not claimed at all: requests to them fall through to your app's own routes.

Outside development — including the test environment — the read API is unreachable until you name who may use it:

```ruby
InertiaRails.configure do |config|
  config.devtools = true
  config.devtools_authorize = -> { Current.user&.admin? }
end
```

The callable runs in the read API controller, so it can read `session`, `cookies`, and `request`.

The extension polls the read API continuously, so those requests are kept out of the log. Set `config.devtools_silence_logs = false` if you are debugging the integration itself and want to see them. Only the `/_inertia/devtools` paths are silenced; your app's own requests log normally.

## Redaction

Values under a sensitive key are replaced with `[REDACTED]` before anything is written to disk — in props, request and response bodies, and URL query parameters. Sensitive request and response headers are redacted too.

Matching is exact and case-insensitive, so `api_key` is redacted but `stripe_api_key` is not. Extend the lists rather than replacing them if you only mean to add:

```ruby
InertiaRails.configure do |config|
  config.devtools_redact_keys += %w[stripe_api_key]
end
```

Your app's `config.filter_parameters` are honored too, with their standard Rails matching semantics — a key filtered from your logs is filtered from DevTools entries as well.

Redaction is key-based, so it needs a structure to walk. A body Rails has no parser for is parsed as JSON and redacted; if it isn't JSON, it is recorded as omitted rather than written out raw. That applies in both directions — an HTML page or a text blob could embed a CSRF token or a secret under no key we can match, so non-Inertia responses are only stored when they are JSON.

## Storage

Entries are written to `tmp/inertia-devtools` as one JSON file each, after the response has been sent. They are pruned after 24 hours, and at most 100 entries are kept per browser tab — requests that carry no tab header, such as initial document loads, form their own group under the same cap. A write failure is reported once and suppresses recording for 30 seconds rather than retrying on every request.

Buffered non-Inertia response bodies and unparsed request bodies over 256 KB are recorded as omitted. Inertia pages retain their complete page and prop payloads so the panel sees the same data as the client.

Recording never changes the response your app produced: if anything in the recorder raises, the entry is dropped and the request is served as if DevTools were off.

## Configuration

| Option                     | Default                     | Description                                                                                                |
| -------------------------- | --------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `devtools`                 | `nil`                       | `nil` records in development only; `true` or `false` force it on or off.                                   |
| `devtools_except`          | `[]`                        | Request paths never recorded. Strings such as `admin/*` are matched with `File.fnmatch`; regexps work too. |
| `devtools_storage_path`    | `tmp/inertia-devtools`      | Where entries are written.                                                                                 |
| `devtools_ttl`             | `24`                        | Hours an entry is kept. Fractional values are allowed.                                                     |
| `devtools_prune_interval`  | `300`                       | Seconds between prunes. `0` prunes on every request.                                                       |
| `devtools_limit`           | `100`                       | Entries kept per browser tab, and per the tab-less group. `0` disables the cap.                            |
| `devtools_max_entries`     | `0`                         | Optional total entry cap across all tabs. Disabled by default.                                             |
| `devtools_authorize`       | `nil`                       | Callable gating the read API everywhere except development.                                                |
| `devtools_silence_logs`    | `true`                      | Keep read API requests out of the log. `false` logs them like any other request.                           |
| `devtools_redact_keys`     | passwords, tokens, secrets  | Prop, body, and query keys replaced with `[REDACTED]`.                                                     |
| `devtools_redact_headers`  | cookie, authorization, CSRF | Header names replaced with `[REDACTED]`.                                                                   |
| `devtools_component_paths` | `nil`                       | Directories searched for the page file backing a component. Auto-detected when `nil`.                      |
