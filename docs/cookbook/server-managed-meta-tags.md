# Server Managed Meta Tags

Inertia Rails can manage a page's meta tags on the server instead of on the frontend. This means that link previews (such as on Facebook, LinkedIn, etc.) will include correct meta _without server-side rendering_.

Inertia Rails renders server defined meta tags into both the server rendered HTML and the client-side Inertia page props. Because the tags share unique `head-key` attributes, the client will "take over" the meta tags after the initial page load.

@available_since rails=3.10.0

## Setup

### Server Side

Simply add the `inertia_meta_tags` helper to your layout. This will render the meta tags in the `<head>` section of your HTML.

```erb
<!-- app/views/layouts/application.html.erb (or your custom layout) -->

<!DOCTYPE html>
<html>
  <head>
    ...
    <%= inertia_meta_tags %> <!-- Add this inside your <head> tag --> // [!code ++]
    <title inertia>My Inertia App</title> <!-- Remove existing title --> // [!code --]
  </head>
</html>
```

> [!NOTE]
> Make sure to remove the `<title>` tag in your Rails layout if you plan to manage it with Inertia Rails. Otherwise you will end up with duplicate `<title>` tags.

### Client Side

Copy the following code into your application. It should be rendered **once** in your application, such as in a [layout component
](/guide/pages#creating-layouts).

:::tabs key:frameworks
== Vue

```vue
<script>
import { Head } from '@inertiajs/vue3'
import { usePage } from '@inertiajs/vue3'
import { h } from 'vue'

export default {
  name: 'MetaTags',
  setup() {
    const page = usePage()

    return () => {
      const metaTags = page.props._inertia_meta || []

      return h(Head, {}, () =>
        metaTags.map((meta) => {
          const { tagName, innerContent, headKey, httpEquiv, ...attrs } = meta

          const attributes = {
            key: headKey,
            'head-key': headKey,
            ...attrs,
          }

          if (httpEquiv) {
            attributes['http-equiv'] = httpEquiv
          }

          let content = null
          if (innerContent != null) {
            content =
              typeof innerContent === 'string'
                ? innerContent
                : JSON.stringify(innerContent)
          }

          return h(tagName, attributes, content)
        }),
      )
    }
  },
}
</script>
```

== React

```jsx
import React from 'react'
import { Head, usePage } from '@inertiajs/react'

const MetaTags = () => {
  const { _inertia_meta: meta } = usePage().props
  return (
    <Head>
      {meta.map((meta) => {
        const { tagName, innerContent, headKey, httpEquiv, ...attrs } = meta

        let stringifiedInnerContent
        if (innerContent != null) {
          stringifiedInnerContent =
            typeof innerContent === 'string'
              ? innerContent
              : JSON.stringify(innerContent)
        }

        return React.createElement(tagName, {
          key: headKey,
          'head-key': headKey,
          ...(httpEquiv ? { 'http-equiv': httpEquiv } : {}),
          ...attrs,
          ...(stringifiedInnerContent
            ? { dangerouslySetInnerHTML: { __html: stringifiedInnerContent } }
            : {}),
        })
      })}
    </Head>
  )
}

export default MetaTags
```

== Svelte 4|Svelte 5

```svelte
<!-- MetaTags.svelte -->
<script>
  import { onMount } from 'svelte'
  import { page } from '@inertiajs/svelte'

  $: metaTags = ($page.props._inertia_meta ?? []).map(
    ({ tagName, headKey, innerContent, httpEquiv, ...attrs }) => ({
      tagName,
      headKey,
      innerContent,
      attrs: httpEquiv ? { ...attrs, 'http-equiv': httpEquiv } : attrs,
    }),
  )

  // Svelte throws warnings if we render void elements like meta with content
  $: voidTags = metaTags.filter((tag) => tag.innerContent == null)
  $: contentTags = metaTags.filter((tag) => tag.innerContent != null)

  let ready = false

  onMount(() => {
    // Clean up server-rendered tags
    document.head.querySelectorAll('[inertia]').forEach((el) => el.remove())

    ready = true
  })
</script>

<svelte:head>
  {#if ready}
    <!-- Void elements (no content) -->
    {#each voidTags as tag (tag.headKey)}
      <svelte:element this={tag.tagName} inertia={tag.headKey} {...tag.attrs} />
    {/each}

    <!-- Elements with content -->
    {#each contentTags as tag (tag.headKey)}
      <svelte:element this={tag.tagName} inertia={tag.headKey} {...tag.attrs}>
        {@html typeof tag.innerContent === 'string'
          ? tag.innerContent
          : JSON.stringify(tag.innerContent)}
      </svelte:element>
    {/each}
  {/if}
</svelte:head>
```

:::

## Rendering Meta Tags

Tags are defined as plain hashes and conform to the following structure:

```ruby
# All fields are optional.
{
  # Defaults to "meta" if not provided
  tag_name: "meta",

  # Used for <meta http-equiv="...">
  http_equiv: "Content-Security-Policy",

  # Used to deduplicate tags. InertiaRails will auto-generate one if not provided
  head_key: "csp-header",

  # Used with <script>, <title>, etc.
  inner_content: "Some content",

  # Any additional attributes will be passed directly to the tag.
  # For example: name: "description", content: "Page description"
  name: "description",
  content: "A description of the page"
}
```

The `<title>` tag has shortcut syntax:

```ruby
{ title: "The page title" }
```

### In the renderer

Add meta tags to an action by passing an array of hashes to the `meta:` option in the `render` method:

```ruby
class EventsController < ApplicationController
  def show
    event = Event.find(params[:id])

    render inertia: 'Event/Show', props: { event: event.as_json }, meta: [
      { title: "Check out the #{event.name} event!" },
      { name: 'description', content: event.description },
      { tag_name: 'script', type: 'application/ld+json', inner_content: { '@context': 'https://schema.org', '@type': 'Event', name: 'My Event' } }
    ]
  end
end
```

### Shared Meta Tags

Often, you will want to define default meta tags that are shared across certain pages and which you can override within a specific controller or action. Inertia Rails has an `inertia_meta` controller instance method which references a store of meta tag data.

You can call it anywhere in a controller to manage common meta tags, such as in `before_action` callbacks or directly in an action.

```ruby
class EventsController < ApplicationController
  before_action :set_meta_tags

  def show
    render inertia: 'Event/Show', props: { event: Event.find(params[:id]) }
  end

  private

  def set_meta_tags
    inertia_meta.add([
      { title: 'Look at this event!' }
    ])
  end
end
```

#### The `inertia_meta` API

The `inertia_meta` method provides a simple API to manage your meta tags. You can add, remove, or clear tags as needed. The `inertia_meta.remove` method accepts either a `head_key` string or a block to filter tags.

```ruby
# Add a single tag
inertia_meta.add({ title: 'Some Page title' })

# Add multiple tags at once
inertia_meta.add([
  { tag_name: 'meta', name: 'og:description', content: 'A description of the page' },
  { tag_name: 'meta', name: 'twitter:title', content: 'A title for Twitter' },
  { tag_name: 'title', inner_content: 'A title for the page', head_key: 'my_custom_head_key' },
  { tag_name: 'script', type: 'application/ld+json', inner_content: { '@context': 'https://schema.org', '@type': 'Event', name: 'My Event' } }
])

# Remove a specific tag by head_key
inertia_meta.remove("my_custom_head_key")

# Remove tags by a condition
inertia_meta.remove do |tag|
  tag[:tag_name] == 'script' && tag[:type] == 'application/ld+json'
end

# Remove all tags
inertia_meta.clear
```

#### JSON-LD and Script Tags

Inertia Rails supports defining `<script>` tags with `type="application/ld+json"` for structured data. All other script tags will be marked as `type="text/plain"` to prevent them from executing on the client side. Executable scripts should be added either in the Rails layout or using standard techniques in your frontend framework.

```ruby
inertia_meta.add({
  tag_name: "script",
  type: "application/ld+json",
  inner_content: {
    "@context": "https://schema.org",
    "@type": "Event",
    name: "My Event",
    startDate: "2023-10-01T10:00:00Z",
    location: {
      "@type": "Place",
      name: "Event Venue",
      address: "123 Main St, City, Country"
    }
  }
})
```

## Deduplication

> [!NOTE]
> The Svelte adapter does not have a `<Head />` component. Inertia Rails will deduplicate meta tags _on the server_, and the Svelte component above will render them deduplicated accordingly.

### Automatic Head Keys

Inertia Rails relies on the `head-key` attribute and the `<Head />` components that the Inertia.js core uses to [manage meta tags](/guide/title-and-meta) and deduplicate them. Inertia.js core expects us to manage `head-key` attributes and deduplication manually, but Inertia Rails will generate them automatically for you.

- `<meta>` tags will use the `name`,`property`, or `http_equiv` attributes to generate a head key. This enables automatic deduplication of common meta tags like `description`, `og:title`, and `twitter:card`.
- All other tags will deterministically generate a `head-key` based on the tag's attributes.

#### Allowing Duplicates

Sometimes, it is valid HTML to have multiple meta tags with the same name or property. If you want to allow duplicates, you can set the `allow_duplicates` option to `true` when defining the tag.

```ruby
class StoriesController < ApplicationController
  before_action do
    inertia_meta.add({ name: 'article:author', content: 'Tony Gilroy' })
  end

  # Renders a single article:author meta tag
  def single_author
    render inertia: 'Stories/Show'
  end

  # Renders multiple article:author meta tags
  def multiple_authors
    render inertia: 'Stories/Show', meta: [
      { name: 'article:author', content: 'Dan Gilroy', allow_duplicates: true },
    ]
  end
end
```

### Manual Head Keys

Automatic head keys should cover the majority of use cases, but you can set `head_key` manually if you need to control the deduplication behavior more precisely. For example, you may want to do this if you know you will remove a shared meta tag in a specific action.

```ruby
# In a concern or `before_action` callback
inertia_meta.add([
  {
    tag_name: 'meta',
    name: 'description',
    content: 'A description of the page',
    head_key: 'my_custom_head_key'
  },
])

# Later in a specific action
inertia_meta.remove('my_custom_head_key')
```

## Combining Meta Tag Methods

There are multiple ways to manage meta tags in Inertia Rails:

- Adding tags to a Rails layout such as `application.html.erb`.
- Using the `<Head />` component from Inertia.js (or the Svelte head element) in the frontend.
- Using the server driven meta tags feature described here.

Nothing prevents you from using these together, but for organizational purposes, we recommended using only one of the last two techniques.
