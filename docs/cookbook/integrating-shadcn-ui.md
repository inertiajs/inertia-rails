# Integrating `shadcn/ui`

This guide demonstrates how to integrate [shadcn/ui](https://ui.shadcn.com) - a collection of reusable React components - with your Inertia Rails application.

## Getting Started in 5 Minutes

If you're starting fresh, create a new Rails application with Inertia (or skip this step if you already have one):

:::tabs key:languages

== TypeScript

```bash
rails new -JA shadcn-inertia-rails
cd shadcn-inertia-rails

bundle add inertia_rails

rails generate inertia:install --framework=react --typescript --vite --tailwind --no-interactive
Installing Inertia's Rails adapter
...
```

== JavaScript

```bash
rails new -JA shadcn-inertia-rails
cd shadcn-inertia-rails

bundle add inertia_rails

rails generate inertia:install --framework=react --vite --tailwind --no-interactive
Installing Inertia's Rails adapter
...
```

:::

> [!NOTE]
> You can also run `rails generate inertia:install` to run the installer interactively.
> Need more details on the initial setup? Check out our [server-side setup guide](/guide/server-side-setup.md).

## Setting Up Path Aliases

Let's configure our project to work seamlessly with `shadcn/ui`. Choose your path based on whether you're using TypeScript or JavaScript.

:::tabs key:languages

== TypeScript

You'll need to configure two files. First, update your `tsconfig.app.json`:

```json lines
{
  "compilerOptions": {
    // ...
    "baseUrl": ".",
    "paths": {
      "@/*": ["./app/frontend/*"]
    }
  }
  // ...
}
```

Then, set up your `tsconfig.json` to match `shadcn/ui`'s requirements (note the `baseUrl` and `paths` properties are different from the `tsconfig.app.json`):

```json lines
{
  //...
  "compilerOptions": {
    /* Required for shadcn-ui/ui */
    "baseUrl": "./app/frontend",
    "paths": {
      "@/*": ["./*"]
    }
  }
}
```

== JavaScript

Using JavaScript? It's even simpler! Just create a `jsconfig.json`:

```json
{
  "compilerOptions": {
    "baseUrl": "./app/frontend",
    "paths": {
      "@/*": ["./*"]
    }
  }
}
```

:::

## Initializing `shadcn/ui`

Now you can initialize `shadcn/ui` with a single command:

```bash
npx shadcn@latest init

✔ Preflight checks.
✔ Verifying framework. Found Vite.
✔ Validating Tailwind CSS.
✔ Validating import alias.
✔ Which style would you like to use? › New York
✔ Which color would you like to use as the base color? › Neutral
✔ Would you like to use CSS variables for theming? … no / yes
✔ Writing components.json.
✔ Checking registry.
✔ Updating tailwind.config.js
✔ Updating app/frontend/entrypoints/application.css
✔ Installing dependencies.
✔ Created 1 file:
  - app/frontend/lib/utils.js

Success! Project initialization completed.
You may now add components.
```

You're all set! Want to try it out? Add your first component:

```shell
npx shadcn@latest add button
```

Now you can import and use your new button component from `@/components/ui/button`. Happy coding!

> [!NOTE]
> Check out the [`shadcn/ui` components gallery](https://ui.shadcn.com/docs/components/accordion) to explore all the beautiful components at your disposal.


## Troubleshooting

If you're using `vite` and see this error `No Tailwind CSS configuration found at path....` (but do have a `tailwind.config.js`) ensure you've imported the CSS properly.
```
@tailwind base;
@tailwind components;
@tailwind utilities;
```
Reference: [Link to Common Github Issue](https://github.com/shadcn-ui/ui/issues/4677)
