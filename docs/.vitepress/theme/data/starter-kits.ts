export type Framework = 'react' | 'vue' | 'svelte'

export interface StarterKit {
  framework: Framework
  name: string
  tech: string
  url: string
}

export const starterKits: StarterKit[] = [
  {
    framework: 'react',
    name: 'React Starter Kit',
    tech: 'React 19 · TypeScript · shadcn/ui',
    url: 'https://github.com/inertia-rails/react-starter-kit',
  },
  {
    framework: 'vue',
    name: 'Vue Starter Kit',
    tech: 'Vue 3 · TypeScript · shadcn-vue',
    url: 'https://github.com/inertia-rails/vue-starter-kit',
  },
  {
    framework: 'svelte',
    name: 'Svelte Starter Kit',
    tech: 'Svelte 5 · TypeScript · shadcn-svelte',
    url: 'https://github.com/inertia-rails/svelte-starter-kit',
  },
]
