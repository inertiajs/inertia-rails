<div align="center">
  <a href="https://inertia-rails.dev">
    <img src="https://inertia-rails.dev/logo.svg" alt="Inertia Rails" width="150">
  </a>

  <h1>Build frontend experiences with the backend you love</h1>

  <p>
    <strong>Single-page React, Vue, and Svelte apps powered by your existing Rails
    controllers, routes, and authentication. No API required.</strong>
  </p>

  <p>
    <a href="https://rubygems.org/gems/inertia_rails"><img src="https://img.shields.io/gem/v/inertia_rails" alt="Gem version"></a>
    <a href="https://rubygems.org/gems/inertia_rails"><img src="https://img.shields.io/gem/dt/inertia_rails" alt="Downloads"></a>
    <a href="https://github.com/inertiajs/inertia-rails/actions/workflows/push.yml"><img src="https://github.com/inertiajs/inertia-rails/actions/workflows/push.yml/badge.svg" alt="Build status"></a>
    <a href="https://github.com/inertiajs/inertia-rails/blob/master/LICENSE.txt"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license"></a>
    <a href="https://discord.gg/inertiajs"><img src="https://img.shields.io/badge/discord-join-5865F2?logo=discord&logoColor=white" alt="Discord"></a>
  </p>

  <p>
    <a href="https://inertia-rails.dev"><strong>Documentation</strong></a> ·
    <a href="https://inertia-rails.dev/guide/server-side-setup"><strong>Get started</strong></a> ·
    <a href="https://inertia-rails.dev/guide/demo-application"><strong>Demo</strong></a> ·
    <a href="https://discord.gg/inertiajs"><strong>Discord</strong></a>
  </p>
</div>

---

## Your controllers. Your routes. Modern components.

Inertia lets you build a fully client-side rendered single-page app without the
complexity of a separate API. Pass data from Rails directly to React, Vue, or
Svelte as **props** — no REST endpoints, no GraphQL, no client-side data
fetching, no state-management headaches.

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def index
    render inertia: {
      users: User.active.map { |user| user.as_json(only: [:id, :name, :email]) }
    }
  end
end
```

```jsx
// app/frontend/pages/users/index.jsx
import { Link } from '@inertiajs/react'

const Users = ({ users }) => (
  <>
    {users.map((user) => (
      <div key={user.id}>
        <Link href={`/users/${user.id}`}>{user.name}</Link>
        <p>{user.email}</p>
      </div>
    ))}
  </>
)

export default Users
```

That's the whole loop: the controller returns props, the component renders them.
Links and form submits are intercepted and turned into XHR visits, so navigation
feels instant — but you're still writing plain Rails on the server.

## Get started

**Add to an existing Rails app** — the installer sets up Vite, your chosen framework, and example pages:

```bash
bundle add inertia_rails
bin/rails generate inertia:install
```

**Or start from a kit** with authentication, Vite, optional SSR, and Kamal
deployment already wired up:

- [React Starter Kit](https://github.com/inertia-rails/react-starter-kit) — React 19 · TypeScript · shadcn/ui
- [Vue Starter Kit](https://github.com/inertia-rails/vue-starter-kit) — Vue 3 · TypeScript · shadcn-vue
- [Svelte Starter Kit](https://github.com/inertia-rails/svelte-starter-kit) — Svelte 5 · TypeScript · shadcn-svelte

Full walkthrough: **[Server-side setup](https://inertia-rails.dev/guide/server-side-setup)** and **[Client-side setup](https://inertia-rails.dev/guide/client-side-setup)**.

## Built for real Rails apps

| | |
|---|---|
| **[Forms that work](https://inertia-rails.dev/guide/forms)** | Validation errors flow from Rails to your components automatically — no manual wiring. |
| **[Server-side rendering](https://inertia-rails.dev/guide/server-side-rendering)** | Full SSR for SEO and fast first paint. Your React/Vue/Svelte, rendered on Rails. |
| **[Test like Rails](https://inertia-rails.dev/guide/testing)** | RSpec and Minitest matchers that feel native. Assert on props, components, and more. |
| **[Partial reloads](https://inertia-rails.dev/guide/partial-reloads)** | Refresh only the data you need. Keep interactions snappy without full page loads. |
| **[Shared data](https://inertia-rails.dev/guide/shared-data)** | Current user, flash, permissions — available on every page automatically. |
| **[Deferred props](https://inertia-rails.dev/guide/deferred-props)** | Load the page fast, fetch expensive data after, with built-in loading states. |
| **[Rails generators](https://inertia-rails.dev/guide/server-side-setup)** | Scaffold entire CRUD interfaces — controllers with matching components. |
| **[History encryption](https://inertia-rails.dev/guide/history-encryption)** | Keep sensitive data private, even in browser history. Toggle per page. |

## Why Inertia?

Inertia sits between traditional server-rendered apps and full SPAs.

**vs. Hotwire** — Same monolith, different view layer. Both keep you in Rails;
Inertia gives you the full React/Vue/Svelte component model and the npm
ecosystem instead of HTML-over-the-wire. Choose Hotwire for minimal JS and
server-rendered HTML; choose Inertia for a modern component architecture.

**vs. API + SPA** — Same frontend, no API hassle. Both give you React/Vue/Svelte,
but Inertia removes the API layer entirely: one router (Rails), Rails sessions
instead of a JWT/OAuth dance, and props from your controller instead of fetching
in `useEffect`. Choose an API for public/mobile clients; choose Inertia for
focused web products. (You can always add an API alongside Inertia later.)

See the full [comparison and FAQ](https://inertia-rails.dev/#why-inertia) →

## Documentation

Everything lives at **[inertia-rails.dev](https://inertia-rails.dev)**:

- [How it works](https://inertia-rails.dev/guide/how-it-works)
- [Pages & layouts](https://inertia-rails.dev/guide/pages)
- [Forms & validation](https://inertia-rails.dev/guide/forms)
- [Shared data](https://inertia-rails.dev/guide/shared-data) · [Partial reloads](https://inertia-rails.dev/guide/partial-reloads) · [Deferred props](https://inertia-rails.dev/guide/deferred-props)
- [Server-side rendering](https://inertia-rails.dev/guide/server-side-rendering)
- [Testing](https://inertia-rails.dev/guide/testing)
- [Configuration reference](https://inertia-rails.dev/guide/configuration)

## Community

- [Awesome Inertia Rails](https://inertia-rails.dev/awesome) — gems, tutorials, and real-world apps
- [Discord](https://discord.gg/inertiajs) — ask questions, get answers fast
- [GitHub Discussions & Issues](https://github.com/inertiajs/inertia-rails/issues) — browse the source, report bugs

## Contributing

Bug reports and pull requests are welcome. To run the test suite:

```bash
bundle install
bundle exec rspec
```

See the [Code of Conduct](CODE_OF_CONDUCT.md). Everyone interacting with the
project is expected to follow it.

## Credits

Inertia Rails is part of the official [Inertia.js](https://inertiajs.com)
organization. It was originally created by the team at
[bellaWatt](https://bellawatt.com) and is maintained by the Inertia.js community.

Released under the [MIT License](LICENSE.txt).
