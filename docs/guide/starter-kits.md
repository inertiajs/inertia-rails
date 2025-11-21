# Inertia Rails Starter Kits

## Overview

Inertia Rails starter kits provide modern, full-stack scaffolding for building Rails applications with React, Vue, or Svelte frontends using Inertia.js. These starter kits are inspired by Laravel's starter kit ecosystem and offer the fastest way to begin building Inertia-powered Rails applications.

<script setup>
import { useData } from 'vitepress';

const { isDark } = useData()
</script>

<img :src="`/images/starter-kit-${isDark ? 'dark' : 'light'}.png`" title="Inertia Rails Starter Kit welcome screen">

## Key Features

- [Inertia Rails](https://inertia-rails.dev) & [Vite Rails](https://vite-ruby.netlify.app) setup
- [React](https://react.dev) frontend with TypeScript & [shadcn/ui](https://ui.shadcn.com) component library
- User authentication system (based on [Authentication Zero](https://github.com/lazaronixon/authentication-zero))
- [Kamal](https://kamal-deploy.org/) for deployment
- Optional SSR support

## Available Starter Kits

### React Starter Kit

**Repository:** [inertia-rails/react-starter-kit](https://github.com/inertia-rails/react-starter-kit)

### Vue Starter Kit

**Repository:** [inertia-rails/vue-starter-kit](https://github.com/inertia-rails/vue-starter-kit)

### Svelte Starter Kit

**Repository:** [inertia-rails/svelte-starter-kit](https://github.com/inertia-rails/svelte-starter-kit)

## Getting Started

Each starter kit repository includes detailed setup instructions. The typical workflow:

1. Clone the desired starter kit repository
2. Run `bin/setup`
