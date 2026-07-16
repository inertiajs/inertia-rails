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

Sometimes it's necessary to redirect outside of your Inertia app: to another website, or to a non-Inertia endpoint in your own app. These destinations can't be visited as Inertia pages — the client has to leave the SPA with a full `window.location` visit. The server triggers that visit by responding with an Inertia location response: `409 Conflict` with the destination URL in the `X-Inertia-Location` header.

Inertia Rails generates these responses in two ways: automatically for cross-origin redirects, and explicitly for same-origin redirects marked with `inertia: { full_page: true }`.

### Cross-Origin Redirects

@available_since rails=master

A regular redirect to another origin works out of the box — Inertia Rails automatically converts it into an Inertia location response for Inertia requests:

```ruby
redirect_to 'https://checkout.stripe.com/session_123', allow_other_host: true
```

Without the conversion, such a redirect can never succeed: the browser follows XHR redirects transparently, and the follow-up request to the external origin fails CORS checks.

The conversion applies to `301`, `302`, and `303` responses. Method-preserving `307` and `308` redirects are left untouched, since a `window.location` visit cannot preserve the HTTP method. It applies to all Inertia requests, including background ones such as polling and prefetching.

You can disable this behavior with the [`convert_external_redirects`](/guide/configuration#convert_external_redirects) configuration option.

### Same-Origin Redirects

@available_since rails=master

Redirects to a non-Inertia endpoint on the same origin can't be converted automatically: a `Location` header doesn't reveal whether its target renders an Inertia page, and converting every same-origin redirect would turn regular Inertia navigation into full page loads. A plain `redirect_to` fails differently here — the browser follows the redirect transparently, the non-Inertia endpoint responds without the `X-Inertia` header, and the client rejects it as an invalid Inertia response.

Mark such redirects explicitly with `inertia: { full_page: true }`:

```ruby
redirect_to admin_path, inertia: { full_page: true }
```

For Inertia requests, the redirect is converted into an Inertia location response, even when `convert_external_redirects` is disabled. For non-Inertia requests, it stays a regular redirect.

The mark requires a `301`, `302`, or `303` redirect. Combining it with a method-preserving `307` or `308` status raises an `ArgumentError`, since a `window.location` visit cannot preserve the HTTP method.

> [!TIP]
> If a whole section of your app is non-Inertia, you can guard it on the target side instead, so that any Inertia request that reaches it — through a followed redirect or a stale link — is bounced into a full page visit:
>
> ```ruby
> class NonInertiaBaseController < ApplicationController
>   before_action -> { inertia_location(request.original_url) if request.inertia? }
> end
> ```

### `inertia_location`

On older versions of Inertia Rails, where the automatic conversion above is not available, use the `inertia_location` method, which generates the Inertia location response directly:

```ruby
inertia_location 'https://checkout.stripe.com/session_123'
```

For Inertia requests, it generates a `409 Conflict` response with the destination URL in the `X-Inertia-Location` header. For non-Inertia requests (for example, a direct browser visit to the same endpoint), it performs a regular redirect — on older versions of Inertia Rails, it responds with `409 Conflict` regardless of the request type.

> [!WARNING]
> `inertia_location` bypasses Rails' open redirect protection. Only pass trusted URLs to it, and don't redirect to user-provided URLs.
