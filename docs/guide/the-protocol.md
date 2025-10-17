# The protocol

This page contains a detailed specification of the Inertia protocol. Be sure to read the [how it works](/guide/how-it-works.md) page first for a high-level overview.

## HTML responses

The very first request to an Inertia app is just a regular, full-page browser request, with no special Inertia headers or data. For these requests, the server returns a full HTML document.

This HTML response includes the site assets (CSS, JavaScript) as well as a root `<div>` in the page's body. The root `<div>` serves as a mounting point for the client-side app, and includes a `data-page` attribute with a JSON encoded [page object] for the initial page. Inertia uses this information to boot your client-side framework and display the initial page component.

```http
REQUEST
GET: http://example.com/events/80
Accept: text/html, application/xhtml+xml


RESPONSE
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8

<html>
<head>
    <title>My app</title>
    <link href="/css/app.css" rel="stylesheet">
    <script src="/js/app.js" defer></script>
</head>
<body>

<div id="app" data-page='{"component":"Event","props":{"errors":{},"event":{"id":80,"title":"Birthday party","start_date":"2019-06-02","description":"Come out and celebrate Jonathan&apos;s 36th birthday party!"}},"url":"/events/80","version":"6b16b94d7c51cbe5b1fa42aac98241d5"}'></div>

</body>
</html>
```

> [!NOTE]
> While the initial response is HTML, Inertia does not server-side render the JavaScript page components by default (see [Server-side Rendering](/guide/server-side-rendering)).

## Inertia responses

Once the Inertia app has been booted, all subsequent requests to the site are made via XHR with a `X-Inertia` header set to `true`. This header indicates that the request is being made by Inertia and isn't a standard full-page visit.

When the server detects the `X-Inertia` header, instead of responding with a full HTML document, it returns a JSON response with an encoded [page object].

```http
REQUEST
GET: http://example.com/events/80
Accept: text/html, application/xhtml+xml
X-Requested-With: XMLHttpRequest
X-Inertia: true
X-Inertia-Version: 6b16b94d7c51cbe5b1fa42aac98241d5

RESPONSE
HTTP/1.1 200 OK
Content-Type: application/json
Vary: X-Inertia
X-Inertia: true

{
  "component": "Event",
  "props": {
    "errors": {},
    "event": {
      "id": 80,
      "title": "Birthday party",
      "start_date": "2019-06-02",
      "description": "Come out and celebrate Jonathan's 36th birthday party!"
    }
  },
  "url": "/events/80",
  "version": "6b16b94d7c51cbe5b1fa42aac98241d5",
  "encryptHistory": true,
  "clearHistory": false
}
```

## Request headers

The following headers are automatically sent by Inertia when making requests. You don't need to set these manually, they're handled by the Inertia client-side adapter.

1. `X-Inertia`: Set to `true` to indicate this is an Inertia request.
2. `X-Requested-With`: Set to `XMLHttpRequest` on all Inertia requests.
3. `Accept`: Set to `text/html, application/xhtml+xml` to indicate acceptable response types.
4. `X-Inertia-Version`: The current asset version to check for asset mismatches.
5. `Purpose`: Set to `prefetch` when making [prefetch](/guide/prefetching) requests.
6. `X-Inertia-Partial-Component`: The component name for [partial reloads](/guide/partial-reloads).
7. `X-Inertia-Partial-Data`: Comma-separated list of props to include in partial reloads.
8. `X-Inertia-Partial-Except`: Comma-separated list of props to exclude from partial reloads.
9. `X-Inertia-Reset`: Comma-separated list of props to reset on navigation.
10. `Cache-Control`: Set to `no-cache` for reload requests to prevent serving stale content.
11. `X-Inertia-Error-Bag`: Specifies which error bag to use for [validation errors](/guide/validation).
12. `X-Inertia-Infinite-Scroll-Merge-Intent`: Indicates whether the requested data should be appended or prepended when using [Infinite scroll](/guide/infinite-scroll).

## Response headers

The following headers should be sent by your server-side adapter in Inertia responses. If you're using Rails server-side adapter, these are handled automatically.

1. `X-Inertia`: Set to true to confirm this is an Inertia response.
2. `X-Inertia-Location`: Used for external redirects when a `409 Conflict` response is returned due to asset version mismatches.
3. `Vary`: Set to `X-Inertia` to help browsers correctly differentiate between HTML and JSON responses. This header must be included on both HTML and JSON responses to prevent browsers from showing JSON content instead of rendered HTML or triggering Inertia error handling for normal page visits. Some browsers require this header on all responses, including redirects that lead to Inertia endpoints.

## The page object

Inertia shares data between the server and client via a page object. This object includes the necessary information required to render the page component, update the browser's history state, and track the site's asset version. The page object can include the following properties:

1. `component`: The name of the JavaScript page component.
2. `props`: The page props. Contains all of the page data along with an `errors` object (defaults to `{}` if there are no errors).
3. `url`: The page URL.
4. `version`: The current asset version.
5. `encryptHistory`: Whether or not to encrypt the current page's history state.
6. `clearHistory`: Whether or not to clear any encrypted history state.
7. `mergeProps`: Array of prop keys that should be merged (appended) during navigation. See the [merging props](/guide/merging-props) documentation for details.
8. `prependProps`: Array of prop keys that should be prepended during navigation.
9. `deepMergeProps`: Array of prop keys that should be deep merged during navigation.
10. `matchPropsOn`: Array of prop keys to use for matching when merging props.
11. `scrollProps`: Configuration for infinite scroll prop merging behavior.
12. `deferredProps`: Configuration for client-side lazy loading of props. See the [deferred props](/guide/deferred-props) documentation for details.

On standard full page visits, the page object is JSON encoded into the `data-page` attribute in the root `<div>`. On Inertia visits, the page object is returned as the JSON payload.

### Basic page object

A minimal page object contains the core properties.

```json
{
  "component": "User/Edit",
  "props": {
    "user": {
      "name": "Jonathan"
    }
  },
  "url": "/user/123",
  "version": "6b16b94d7c51cbe5b1fa42aac98241d5",
  "clearHistory": false,
  "encryptHistory": false
}
```

### Page object with deferred props

When using deferred props, the page object includes a `deferredProps` configuration. Note that deferred props are not included in the initial props since they are loaded in a subsequent request.

```json
{
  "component": "Posts/Index",
  "props": {
    "user": {
      "name": "Jonathan"
    }
  },
  "url": "/posts",
  "version": "6b16b94d7c51cbe5b1fa42aac98241d5",
  "clearHistory": false,
  "encryptHistory": false,
  "deferredProps": {
    "default": ["comments", "analytics"],
    "sidebar": ["relatedPosts"]
  }
}
```

### Page object with merge props

When using merge props, additional configuration is included.

```json
{
  "component": "Feed/Index",
  "props": {
    "user": {
      "name": "Jonathan"
    },
    "posts": [{ "id": 1, "title": "First Post" }],
    "notifications": [{ "id": 2, "message": "New comment" }],
    "conversations": {
      "data": [
        { "id": 1, "title": "Support Chat", "participants": ["John", "Jane"] }
      ]
    }
  },
  "url": "/feed",
  "version": "6b16b94d7c51cbe5b1fa42aac98241d5",
  "clearHistory": false,
  "encryptHistory": false,
  "mergeProps": ["posts"],
  "prependProps": ["notifications"],
  "deepMergeProps": ["conversations"],
  "matchPropsOn": ["posts.id", "notifications.id", "conversations.data.id"]
}
```

### Page object with scroll props

When using [Infinite scroll](/guide/infinite-scroll), the page object includes a `scrollProps` configuration.

```json
{
  "component": "Posts/Index",
  "props": {
    "posts": {
      "data": [
        { "id": 1, "title": "First Post" },
        { "id": 2, "title": "Second Post" }
      ]
    }
  },
  "url": "/posts?page=1",
  "version": "6b16b94d7c51cbe5b1fa42aac98241d5",
  "clearHistory": false,
  "encryptHistory": false,
  "mergeProps": ["posts.data"],
  "scrollProps": {
    "posts": {
      "pageName": "page",
      "previousPage": null,
      "nextPage": 2,
      "currentPage": 1
    }
  }
}
```

## Asset versioning

One common challenge with single-page apps is refreshing site assets when they've been changed. Inertia makes this easy by optionally tracking the current version of the site's assets. In the event that an asset changes, Inertia will automatically make a full-page visit instead of an XHR visit.

The Inertia [page object] includes a `version` identifier. This version identifier is set server-side and can be a number, string, file hash, or any other value that represents the current "version" of your site's assets, as long as the value changes when the site's assets have been updated.

Whenever an Inertia request is made, Inertia will include the current asset version in the `X-Inertia-Version` header. When the server receives the request, it compares the asset version provided in the `X-Inertia-Version` header with the current asset version. This is typically handled in the middleware layer of your server-side framework.

If the asset versions are the same, the request simply continues as expected. However, if the asset versions are different, the server immediately returns a `409 Conflict` response, and includes the URL in a `X-Inertia-Location` header. This header is necessary, since server-side redirects may have occurred. This tells Inertia what the final intended destination URL is.

Note, `409 Conflict` responses are only sent for `GET` requests, and not for `POST/PUT/PATCH/DELETE` requests. That said, they will be sent in the event that a `GET` redirect occurs after one of these requests.

If "flash" session data exists when a `409 Conflict` response occurs, Inertia's server-side framework adapters will automatically reflash this data.

```http
REQUEST
GET: http://example.com/events/80
Accept: text/html, application/xhtml+xml
X-Requested-With: XMLHttpRequest
X-Inertia: true
X-Inertia-Version: 6b16b94d7c51cbe5b1fa42aac98241d5

RESPONSE
409: Conflict
X-Inertia-Location: http://example.com/events/80
```

You can read more about this on the [asset versioning](/guide/asset-versioning) page.

## Partial reloads

When making Inertia requests, the partial reload option allows you to request a subset of the props (data) from the server on subsequent visits to the same page component. This can be a helpful performance optimization if it's acceptable that some page data becomes stale. See the [partial reloads](/guide/partial-reloads) documentation for details.

When a partial reload request is made, Inertia includes the `X-Inertia-Partial-Component` header and may include `X-Inertia-Partial-Data` and/or `X-Inertia-Partial-Except` headers with the request.

The `X-Inertia-Partial-Data` header is a comma separated list of the desired props (data) keys that should be returned.

The `X-Inertia-Partial-Except` header is a comma separated list of the props (data) keys that should not be returned. When only the `X-Inertia-Partial-Except` header is included, all props (data) except those listed will be sent. If both `X-Inertia-Partial-Data` and `X-Inertia-Partial-Except` headers are included, the `X-Inertia-Partial-Except` header will take precedence.

The `X-Inertia-Partial-Component` header includes the name of the component that is being partially reloaded. This is necessary, since partial reloads only work for requests made to the same page component. If the final destination is different for some reason (e.g. the user was logged out and is now on the login page), then no partial reloading will occur.

```http
REQUEST
GET: http://example.com/events
Accept: text/html, application/xhtml+xml
X-Requested-With: XMLHttpRequest
X-Inertia: true
X-Inertia-Version: 6b16b94d7c51cbe5b1fa42aac98241d5
X-Inertia-Partial-Data: events
X-Inertia-Partial-Component: Events

RESPONSE
HTTP/1.1 200 OK
Content-Type: application/json

{
  "component": "Events",
  "props": {
    "auth": {...},       // NOT included
    "categories": [...], // NOT included
    "events": [...],     // included
    "errors": {}         // always included
  },
  "url": "/events/80",
  "version": "6b16b94d7c51cbe5b1fa42aac98241d5"
}
```

## HTTP status codes

Inertia uses specific HTTP status codes to handle different scenarios.

1. `200 OK`: Standard successful response for both HTML and Inertia JSON responses.
2. `302 Found`: Standard redirect response. Inertia's server-side adapters automatically convert this to `303 See Other` when returned after `PUT`, `PATCH`, or `DELETE` requests.
3. `303 See Other`: Used for redirects after non-GET requests. This status code tells the browser to make a `GET` request to the redirect URL, preventing duplicate form submissions that could occur if the browser repeated the original request method.
4. `409 Conflict`: Returned when there's an asset version mismatch or for external redirects. For asset mismatches, this prompts a full page reload. For external redirects, the response includes an `X-Inertia-Location` header and triggers a `window.location` redirect client-side.

[page object]: #the-page-object
