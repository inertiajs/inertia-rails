import type MarkdownIt from 'markdown-it'
import container from 'markdown-it-container'
import type Renderer from 'markdown-it/lib/renderer'
import type Token from 'markdown-it/lib/token'
import { ruleBlockTab } from './ruleBlockTab'

type Params = {
  shareStateKey: string | undefined
}

const parseTabsParams = (input: string): Params => {
  const match = input.match(/key:(\S+)/)
  return {
    shareStateKey: match?.[1],
  }
}

export const tabsMarkdownPlugin = (md: MarkdownIt) => {
  md.use(container, 'tabs', {
    render(tokens: Token[], index: number) {
      const token = tokens[index]
      if (token.nesting === 1) {
        const params = parseTabsParams(token.info)
        const shareStateKeyProp = params.shareStateKey
          ? `sharedStateKey="${md.utils.escapeHtml(params.shareStateKey)}"`
          : ''
        return `<PluginTabs ${shareStateKeyProp}>\n`
      } else {
        return `</PluginTabs>\n`
      }
    },
  })

  md.block.ruler.after('container_tabs', 'tab', ruleBlockTab)
  const renderTab: Renderer.RenderRule = (tokens, index) => {
    const token = tokens[index]
    if (token.nesting === 1) {
      const label = token.info
      const labelProp = `label="${md.utils.escapeHtml(label)}"`
      return `<PluginTabsTab ${labelProp}>\n`
    } else {
      return `</PluginTabsTab>\n`
    }
  }
  md.renderer.rules['tab_open'] = renderTab
  md.renderer.rules['tab_close'] = renderTab
}
