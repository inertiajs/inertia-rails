---
next:
  text: 'Demo Application'
  link: '/guide/demo-application'
---

# Introduction

Welcome to the documentation for [inertia_rails](https://github.com/inertiajs/inertia-rails) adapter for [Ruby on Rails](https://rubyonrails.org/) and [Inertia.js](https://inertiajs.com/).

## Why adapter-specific documentation?

The [official documentation for Inertia.js](https://inertiajs.com) is great, but it's not Rails-specific anymore (see the [legacy docs](https://legacy.inertiajs.com)). This documentation aims to fill in the gaps and provide Rails-specific examples and explanations.

## JavaScript apps the monolith way

Inertia is a new approach to building classic server-driven web apps. We call it the modern monolith.

Inertia allows you to create fully client-side rendered, single-page apps, without the complexity that comes with modern SPAs. It does this by leveraging existing server-side patterns that you already love.

Inertia has no client-side routing, nor does it require an API. Simply build controllers and page views like you've always done! Inertia works great with any backend framework — it was fine-tuned for [Laravel](https://laravel.com), so naturally we had to fine-tune it for [Ruby on Rails](https://rubyonrails.org/) too.

## Not a Framework

Inertia isn't a framework, nor is it a replacement for your existing server-side or client-side frameworks. Rather, it's designed to work with them. Think of Inertia as glue that connects the two. Inertia does this via adapters. We currently have three official client-side adapters (React, Vue, and Svelte) and four server-side adapters (Laravel, Rails, Phoenix, and Django).

## Support Policy

> [!NOTE]
> The `inertia_rails` gem has been on 3.x for years — long before Inertia.js itself reached 3.x. When Inertia.js 4.x arrives, we'll bump the gem to 4.x to align major version numbers and this policy going forward.

Inertia.js follows the same support policy as [Laravel](https://laravel.com/docs/releases#support-policy). When a new major version is released, the previous version receives bug fixes for 6 months and security fixes for 12 months. Inertia.js v3 was released on March 26, 2026.

| Version | Bug Fixes Until    | Security Fixes Until |
| ------- | ------------------ | -------------------- |
| 0.x     | End of life        | End of life          |
| 1.x     | End of life        | End of life          |
| 2.x     | September 26, 2026 | March 26, 2027       |
| 3.x     | TBD                | TBD                  |

## Next Steps

Want to learn a bit more before diving in? Check out the [who is it for](/guide/who-is-it-for) and [how it works](/guide/how-it-works) pages. Or, if you're ready to get started, jump right into the [installation instructions](/guide/server-side-setup).
