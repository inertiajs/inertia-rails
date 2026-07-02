# Redirects

When making a non-GET Inertia request manually or via a `<Link>` element, you should ensure that you always respond with a proper Inertia redirect response.

For example, if your controller is creating a new user, your "create" endpoint should return a redirect back to a standard `GET` endpoint, such as your user "index" page. Inertia will automatically follow this redirect and update the page accordingly.

```ruby
class UsersController < ApplicationController
  def create
    user = User.new(user_params)

    if user.save
      redirect_to users_url
    else
      redirect_to new_user_url, inertia: { errors: user.errors }
    end
  end

  private

  def user_params
    params.expect(user: [:name, :email])
  end
end
```

## 303 Response Code

When redirecting after a `PUT`, `PATCH`, or `DELETE` request, you must use a `303` response code, otherwise the subsequent request will not be treated as a `GET` request. A `303` redirect is very similar to a `302` redirect; however, the follow-up request is explicitly changed to a `GET` request.

If you're using one of our official server-side adapters, all redirects will automatically be converted to `303` redirects.

## Preserving Fragments

@available_since rails=3.19.0 core=3.0.0

Sometimes a user may visit a URL with a fragment, such as `/article/old-slug#section`, and the server needs to redirect to a different URL. The fragment from the original request is normally lost during the redirect.

:::tabs key:frameworks

== Vue

```vue
<Link href="/article/old-slug#section">View section</Link>
```

== React

```jsx
import { Link } from '@inertiajs/react'

export default () => <Link href="/article/old-slug#section">View section</Link>
```

== Svelte

```svelte
<Link href="/article/old-slug#section">View section</Link>
```

:::

You may preserve the fragment by passing `preserve_fragment` on the redirect response. The client will carry over the `#section` fragment to the redirect target, resulting in `/article/new-slug#section`.

```ruby
redirect_to article_path(article), inertia: { preserve_fragment: true }
```

## External Redirects

Sometimes it's necessary to redirect to an external website, or even another non-Inertia endpoint in your app while handling an Inertia request.

@available_since rails=master

A regular redirect works out of the box: Inertia Rails automatically converts redirects to external (cross-origin) URLs into Inertia location responses (`409 Conflict` with the destination URL in the `X-Inertia-Location` header) for Inertia requests. When this response is received client-side, Inertia will automatically perform a `window.location = url` visit.

```ruby
redirect_to 'https://checkout.stripe.com/session_123', allow_other_host: true
```

Without the conversion, such a redirect can never succeed: the browser follows XHR redirects transparently, and the follow-up request to the external origin fails CORS checks.

The conversion applies to `301`, `302`, and `303` responses. Method-preserving `307` and `308` redirects are left untouched, since a `window.location` visit cannot preserve the HTTP method. It applies to all Inertia requests, including background ones such as polling and prefetching.

You can disable this behavior with the [`convert_external_redirects`](/guide/configuration#convert_external_redirects) configuration option.

### `inertia_location`

On older versions of Inertia Rails, or with automatic conversion disabled, use the `inertia_location` method, which generates the Inertia location response directly:

```ruby
inertia_location 'https://checkout.stripe.com/session_123'
```

For Inertia requests, it generates a `409 Conflict` response with the destination URL in the `X-Inertia-Location` header; for non-Inertia requests (for example, a direct browser visit to the same endpoint), it performs a regular redirect.

`inertia_location` is also the way to force a full `window.location` visit to a **same-origin** URL (for example, a non-Inertia endpoint in your app), since automatic conversion deliberately leaves same-origin redirects untouched.

> [!WARNING]
> `inertia_location` bypasses Rails' open redirect protection. Only pass trusted URLs to it, and don't redirect to user-provided URLs.
