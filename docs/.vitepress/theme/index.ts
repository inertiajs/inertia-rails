// https://vitepress.dev/guide/custom-theme
import type { Theme } from 'vitepress'
import { enhanceAppWithTabs } from 'vitepress-plugin-tabs/client'
import DefaultTheme from 'vitepress/theme'
import { h } from 'vue'
import { AvailableSince } from './components'
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
  },
  setup() {
    setupFrameworksTabs()
  },
} satisfies Theme
