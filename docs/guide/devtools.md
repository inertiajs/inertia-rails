# DevTools

@available_since rails=master core=3.6.0

[Inertia DevTools](https://inertiajs.com/docs/v3/advanced/devtools) is a browser extension that records every Inertia request your app makes and shows you its props, headers, route, and merged page state. Inertia Rails implements the server half of the [DevTools protocol](https://inertiajs.com/docs/v3/advanced/devtools-protocol), so recording works with no setup in development.

## Installation

Install the extension from the [Chrome Web Store](https://chromewebstore.google.com/detail/inertiajs-devtools/cbaffpghpcbmgbnlpamegieokkpdlnih) or [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/inertia-js-devtools/), or load a [GitHub release](https://github.com/inertiajs/inertia-devtools/releases) unpacked. The client-side integrations follow the `dev` option of `createInertiaApp`, which defaults to `import.meta.env.DEV`, so Vite apps need nothing else. With another bundler, turn it on for development builds:

```js
createInertiaApp({
  // ...
  dev: true,
})
```

Open your browser's DevTools on your app and pick the **Inertia** panel. Navigate around your application and each visit will appear in the timeline.

> [!NOTE]
> Run the Vite development server for full functionality. In dev mode Inertia exposes the hooks the panel relies on for client-side detail such as visit options and request grouping. Without them, requests are still recorded, but some client-side features are unavailable.

## The Timeline

Every Inertia request is listed in the timeline on the left, with a live indicator while it is in flight. You may filter by method, request type, or status, or search by URL and component. Request types include full visits, [partial reloads](/guide/partial-reloads), [deferred prop loads](/guide/deferred-props), [polls](/guide/polling), [prefetches](/guide/prefetching), and [Precognition validation](/guide/precognition). Related requests are grouped rather than listed separately, so a page visit and its follow-up requests appear together. The grouping is determined on the client because only the browser can tell a poll from a full navigation or know whether a prefetch was served from cache.

## Inspecting a Request

Selecting a request opens its detail, split into four tabs.

The **Props** tab lists every prop as a tree, with a badge indicating whether it is deferred, optional, merged, or shared with `inertia_share`, and a `file:line` link into your editor. Values expand inline. Alongside it, the **HTTP** tab shows the request and response headers and bodies with sensitive values [redacted](#redaction), and the **Route** tab shows the matched route name, URI, and controller action.

The **Page** tab shows the full page state after Inertia has handled the response. A partial reload might send only one prop over the wire, but Inertia merges it into the existing page, so this tab shows the complete result, not only what arrived in the response.

[What gets recorded](#what-gets-recorded) lists the server data behind each tab.

## Client-Side Events

Some interactions never reach the server, so the Network tab shows nothing for them. The extension records them as their own timeline entries: [client-side visits](/guide/manual-visits#client-side-visits) and requests served from the [prefetch](/guide/prefetching) cache.

## Editor Links

File references throughout the panel link directly to your editor. You may use the editor picker in the toolbar to choose your editor. VS Code, PhpStorm, Cursor, and Zed register their URL schemes on install and work out of the box. Sublime Text ships no URL-scheme handler, so its links do nothing until you install one such as [SublimeUrl](https://github.com/inopinatus/sublime_url).

## What gets recorded

Every response is recorded as the browser receives it, whether or not it is an Inertia response, and stamped with an `X-Inertia-Devtools-Id` header. Requests the browser makes for images, stylesheets, scripts, fonts, and sockets are left out. Initial Inertia page loads also render a `<script data-inertia-devtools-id>` tag next to the root element (`inertia_root` does this; call `inertia_devtools_tag` yourself if your layout builds the root element), so the extension can find the entry before any XHR happens.

An app mounted under a path prefix (`map '/admin'` in `config.ru`) also sends the prefix in an `X-Inertia-Devtools-Base-Path` header and on the tag, so the extension reads entries from beneath it.

Requests rendered by Rails exception handling are recorded with their final status. If exceptions are configured to propagate instead, no response comes back to record.

For Inertia renders, the entry also carries:

- **Props** — every top-level prop, and every nested one that has a type or comes from `inertia_share`, keyed by its dot path and badged with its type (`always`, `optional`, `defer`, `merge`, `scroll`, `once`), its defer group, merge direction, and whether it came from `inertia_share`.
- **Editor links** — the file and line of the `render inertia:` call (the action itself for an implicit render, or the `inertia` route definition in development on Rails 8.1+), of the `inertia_share` block each shared prop came from, and of the controller action. Each prop links to the line of its own key on Ruby 3.3+ or with the `prism` gem in your bundle, and to the `render inertia:` call otherwise.
- **Route** — the matched URI pattern (Rails 7.1+), route name (Rails 8.1+), and `Controller#action`.
- **Page** — the full page object the client received.

Deferred and optional props are skipped before resolution on a first load, so they show up on the request that actually delivers them, not on the initial one.

Props renamed by [`prop_transformer`](/guide/configuration#prop-transformer) are shown with their values but without their type, source, or `inertia_share` badge.

## Linking props to serializers

An object that responds to `to_inertia` can be passed as `props:` or used as a prop value, including inside an array or returned from a closure or a prop type's block; Inertia Rails renders the hash it returns. Its props link to the `render inertia:` call by default. To link each one to where the serializer declares it, also define `inertia_prop_sources`, returning `[file, line]` pairs keyed like that hash:

```ruby
class CourseSerializer
  def initialize(course)
    @course = course
  end

  def to_inertia
    { title: title }
  end

  def title
    @course.title
  end

  def inertia_prop_sources
    { 'title' => method(:title).source_location }
  end
end
```

A serializer nested in another one reports its own keys; DevTools adds the path it sits under. `inertia_prop_sources` is only called while DevTools records, and an error inside it is reported and ignored, so the page still renders.

## Enabling and disabling

DevTools has two independent switches, one on the server and one on the client. Both default to on in development and off in production.

Recording is on in development and off everywhere else. Set `config.devtools.enabled` (or the `INERTIA_DEVTOOLS_ENABLED` environment variable, `true` or `false`) to override:

```ruby
InertiaRails.configure do |config|
  config.devtools.enabled = true
end
```

DevTools settings live under `config.devtools` and are global rather than per controller, since recording runs in middleware, so `inertia_config` does not take them. While DevTools is off, the `/_inertia/devtools` paths are not claimed at all: requests to them fall through to your app's own routes.

In development every request is recorded and the read API is open. Everywhere else, the test environment included, nothing is recorded or served until you name who may use DevTools:

```ruby
InertiaRails.configure do |config|
  config.devtools.enabled = true
  config.devtools.authorize = -> { Current.user&.admin? }
  config.devtools.base_controller = 'ApplicationController'
end
```

The callable runs in your own controllers, after their filters, so `Current.user` or Devise's `current_user` is set. It runs on every request while DevTools is enabled, so keep it cheap.

It decides whose requests are recorded: everyone else gets no DevTools headers, tag, or entry. Requests no controller handled, such as routing errors, are recorded only in development without a callable.

It also decides who may read entries. The read API inherits `base_controller`, a bare `ActionController::API` by default, so point it at a controller whose filters sign users in, such as `ApplicationController` or your admin base controller, for the callable to see the same user there. The read API never writes the session back.

> [!NOTE]
> The base controller's filters run on every entry the extension fetches. A filter that expects every action to authorize something, such as Pundit's `verify_authorized`, needs a skip in `InertiaRails::Devtools::EntriesController`. The base controller is read when the app boots: set it in an initializer and restart the server after changing it.

The extension reads an entry for every response it sees, so those requests are kept out of the log. Only the `/_inertia/devtools` paths are silenced; your app's own requests log normally.

On the client, the hooks follow the `dev` option of `createInertiaApp()` shown in [Installation](#installation). These hooks expose the visit options and request grouping described above, so turning them off leaves the timeline recording requests without that client-side detail.

To disable the panel itself, toggle the extension off from your browser's extensions page, such as `chrome://extensions`.

## Redaction

Values under a sensitive key are replaced with `[REDACTED]` before anything is written to disk — in props, request and response bodies, and the query parameters of the request URL, the page URL, redirect locations, and URL headers such as `Referer`. Sensitive request and response headers are redacted too.

`devtools.redact_keys` match exactly and case-insensitively, so `api_key` is redacted but `stripe_api_key` is not. Extend the lists rather than replacing them if you only mean to add:

```ruby
InertiaRails.configure do |config|
  config.devtools.redact_keys += %w[stripe_api_key]
end
```

Request parameters and URL query parameters also honor your app's `config.filter_parameters`, with their standard Rails matching semantics, so what is filtered from your logs is filtered there too. Props and response bodies use only `devtools.redact_keys`: log filters match partially (`:email`, `:_key`) and would hide the values you came to inspect.

Redaction is key-based, so it needs a structure to walk. A body Rails has no parser for is parsed as JSON and redacted; if it isn't JSON, it is recorded as omitted rather than written out raw. That applies in both directions — an HTML page or a text blob could embed a CSRF token or a secret under no key we can match, so non-Inertia responses are only stored when they are JSON. Likewise, the request body of a non-Inertia `POST`, `PUT`, `PATCH`, or `DELETE`, such as a plain Rails form or an API call, is recorded as omitted.

A URL inside a prop or a body is stored as is, query string included. A token in a URL is not a secret anyway: browsers cache it, servers log it, and the `Referer` header passes it on.

## Storage

Entries are written to `tmp/inertia-devtools` as one JSON file each, in a directory per browser tab, before the response is sent: the extension reads each entry once, as soon as the response headers arrive. At most 100 entries are kept per tab — requests the extension has not tagged with a tab, such as the first page load on a host, form their own group under the same cap — and entries older than 24 hours are removed whenever a new tab starts recording. A write failure is reported once and suppresses recording for 30 seconds rather than retrying on every request.

Request bodies other than form data, and buffered non-Inertia response bodies, are recorded as omitted when over 256 KB. Inertia pages retain their complete page and prop payloads so the panel sees the same data as the client.

Recording never breaks a response: if anything in the recorder raises, the error is reported and the entry is dropped, so the extension finds nothing under that response's id.

## Configuration

Settings take plain values; only `authorize` is a callable. `enabled`, `storage_path`, `ttl`, and `limit` can also be set with the `INERTIA_DEVTOOLS_ENABLED`, `INERTIA_DEVTOOLS_STORAGE_PATH`, `INERTIA_DEVTOOLS_TTL`, and `INERTIA_DEVTOOLS_LIMIT` environment variables.

| Option                     | Default                                                        | Description                                                                                                                                     |
| -------------------------- | -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `devtools.enabled`         | `nil`                                                          | `nil` records in development only; `true` or `false` force it on or off.                                                                        |
| `devtools.except`          | `[]`                                                           | Request paths never recorded. Strings such as `admin/*` are matched with `File.fnmatch`; regexps work too.                                      |
| `devtools.storage_path`    | `tmp/inertia-devtools`                                         | Where entries are written, relative to the app root.                                                                                            |
| `devtools.ttl`             | `24`                                                           | Hours an entry is kept. Fractional values are allowed.                                                                                          |
| `devtools.limit`           | `100`                                                          | Entries kept per browser tab, and per the tab-less group. `0` disables the cap.                                                                 |
| `devtools.authorize`       | `nil`                                                          | Callable, run in your controllers, deciding whose requests are recorded and who may read them. Without one, DevTools works in development only. |
| `devtools.base_controller` | `'ActionController::API'`                                      | Controller the read API inherits. Set it to one that signs users in when you use `authorize`.                                                   |
| `devtools.redact_keys`     | passwords, tokens, secrets                                     | Prop, body, and query keys replaced with `[REDACTED]`.                                                                                          |
| `devtools.redact_headers`  | cookie, authorization, CSRF                                    | Header names replaced with `[REDACTED]`.                                                                                                        |
| `devtools.component_paths` | `app/frontend/pages`, `app/javascript/pages` (and capitalized) | Directories searched for the page file backing a component.                                                                                     |
