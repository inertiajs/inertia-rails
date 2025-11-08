// https://vitepress.dev/guide/custom-theme
import type { Theme } from 'vitepress'
import { enhanceAppWithTabs } from 'vitepress-plugin-tabs/client'
import DefaultTheme from 'vitepress/theme'
import { h } from 'vue'
import {
  AvailableSince,
  Opt,
  React,
  Svelte,
  Svelte4,
  Svelte5,
  Vue,
} from './components'
import { setupFrameworksTabs } from './frameworksTabs'
import './style.css'

export default {
  extends: DefaultTheme,
  Layout: () => {
    return h(DefaultTheme.Layout, null, {
      // https://vitepress.dev/guide/extending-default-theme#layout-slots
    })
  },
  enhanceApp({ app, router, siteData }) {
    enhanceAppWithTabs(app)
    app.component('AvailableSince', AvailableSince)
    app.component('Opt', Opt)
    app.component('React', React)
    app.component('Vue', Vue)
    app.component('Svelte', Svelte)
    app.component('Svelte4', Svelte4)
    app.component('Svelte5', Svelte5)
  },
  setup() {
    setupFrameworksTabs()
  },
} satisfies Theme
