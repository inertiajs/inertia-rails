import { execSync } from 'child_process'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from './vitepress-plugin-tabs/tabsMarkdownPlugin'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

const title = 'Inertia Rails'
const description = 'Documentation for Inertia.js Rails adapter'
const site = 'https://inertia-rails.dev'
const image = `${site}/og_image.jpg`

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title,
  description,

  cleanUrls: true,

  vite: {
    plugins: [
      {
        name: 'generate-llm-docs',
        buildStart() {
          // Regenerate LLM docs before build
          console.log('Regenerating LLM documentation...')
          execSync('node scripts/extract-docs.js', {
            cwd: join(__dirname, '..'),
          })
          console.log('LLM documentation updated!')
        },
      },
    ],
  },

  markdown: {
    config(md) {
      md.use(tabsMarkdownPlugin)
    },
  },

  head: [
    ['link', { rel: 'icon', href: '/favicon.ico', sizes: '32x32' }],
    ['link', { rel: 'icon', href: '/icon.svg', type: 'image/svg+xml' }],

    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:site', content: site }],
    ['meta', { name: 'twitter:description', value: description }],
    ['meta', { name: 'twitter:image', content: image }],

    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:locale', content: 'en_US' }],
    ['meta', { property: 'og:site', content: site }],
    ['meta', { property: 'og:site_name', content: title }],
    ['meta', { property: 'og:image', content: image }],
    ['meta', { property: 'og:description', content: description }],
  ],

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide' },
      { text: 'Cookbook', link: '/cookbook/integrating-shadcn-ui' },
      { text: 'Awesome', link: '/awesome' },
      {
        text: 'Links',
        items: [
          { text: 'Official Inertia.js docs', link: 'https://inertiajs.com' },
          {
            text: 'Gems',
            items: [
              {
                text: 'inertia_rails',
                link: 'https://github.com/inertiajs/inertia-rails',
              },
              {
                text: 'inertia_rails-contrib',
                link: 'https://github.com/skryukov/inertia_rails-contrib',
              },
            ],
          },
        ],
      },
    ],

    logo: '/logo.svg',

    sidebar: {
      '/guide': [
        {
          items: [
            { text: 'Introduction', link: '/guide' },
            { text: 'Demo app', link: '/guide/demo-application' },
            { text: 'Upgrade guide', link: '/guide/upgrade-guide' },
          ],
        },
        {
          text: 'Installation',
          items: [
            { text: 'Server-side', link: '/guide/server-side-setup' },
            { text: 'Client-side', link: '/guide/client-side-setup' },
          ],
        },
        {
          text: 'Core concepts',
          items: [
            { text: 'Who is it for', link: '/guide/who-is-it-for' },
            { text: 'How it works', link: '/guide/how-it-works' },
            { text: 'The protocol', link: '/guide/the-protocol' },
          ],
        },
        {
          text: 'The basics',
          items: [
            { text: 'Pages', link: '/guide/pages' },
            { text: 'Responses', link: '/guide/responses' },
            { text: 'Redirects', link: '/guide/redirects' },
            { text: 'Routing', link: '/guide/routing' },
            { text: 'Title & meta', link: '/guide/title-and-meta' },
            { text: 'Links', link: '/guide/links' },
            { text: 'Manual visits', link: '/guide/manual-visits' },
            { text: 'Forms', link: '/guide/forms' },
            { text: 'File uploads', link: '/guide/file-uploads' },
            { text: 'Validation', link: '/guide/validation' },
          ],
        },
        {
          text: 'Data & Props',
          items: [
            { text: 'Shared data', link: '/guide/shared-data' },
            { text: 'Partial reloads', link: '/guide/partial-reloads' },
            { text: 'Deferred props', link: '/guide/deferred-props' },
            { text: 'Polling', link: '/guide/polling' },
            { text: 'Prefetching', link: '/guide/prefetching' },
            { text: 'Load when visible', link: '/guide/load-when-visible' },
            { text: 'Merging props', link: '/guide/merging-props' },
            { text: 'Remembering state', link: '/guide/remembering-state' },
          ],
        },
        {
          text: 'Security',
          items: [
            { text: 'Authentication', link: '/guide/authentication' },
            { text: 'Authorization', link: '/guide/authorization' },
            { text: 'CSRF protection', link: '/guide/csrf-protection' },
            { text: 'History encryption', link: '/guide/history-encryption' },
          ],
        },
        {
          text: 'Advanced',
          items: [
            { text: 'Asset versioning', link: '/guide/asset-versioning' },
            { text: 'Code splitting', link: '/guide/code-splitting' },
            { text: 'Configuration', link: '/guide/configuration' },
            { text: 'Error handling', link: '/guide/error-handling' },
            { text: 'Events', link: '/guide/events' },
            { text: 'Progress indicators', link: '/guide/progress-indicators' },
            { text: 'Scroll management', link: '/guide/scroll-management' },
            {
              text: 'Server-side rendering',
              link: '/guide/server-side-rendering',
            },
            { text: 'Testing', link: '/guide/testing' },
          ],
        },
      ],
      '/cookbook': [
        {
          items: [
            {
              text: 'Integrations',
              items: [
                { text: 'shadcn/ui', link: '/cookbook/integrating-shadcn-ui' },
                { text: 'Inertia Modal', link: '/cookbook/inertia-modal' },
              ],
            },
            {
              text: 'Troubleshooting',
              items: [
                {
                  text: 'Rails validation error types',
                  link: '/cookbook/handling-validation-error-types',
                },
              ],
            },
          ],
        },
      ],
    },

    search: {
      provider: 'algolia',
      options: {
        appId: 'BWKGTG68ZO',
        apiKey: '06bc959e3f6ab7eb186cd27653408b04',
        indexName: 'inertia-rails',
      },
    },

    editLink: {
      pattern:
        'https://github.com/inertiajs/inertia-rails/edit/master/docs/:path',
      text: 'Edit this page on GitHub',
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/inertiajs/inertia-rails' },
      { icon: 'x', link: 'https://x.com/inertiajs' },
      { icon: 'discord', link: 'https://discord.gg/inertiajs' },
    ],
  },
})
