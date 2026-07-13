import MarkdownIt from 'markdown-it'

export interface AvailableSinceParams {
  rails?: string
  core?: string
  description?: string
}

function parseAvailableSinceParams(info: string): AvailableSinceParams {
  const basicMatch = info.trim().match(/^available_since(?:\s+(.*))?$/)
  if (!basicMatch) return {}

  const allParams = basicMatch[1] || ''
  const params: AvailableSinceParams = {}

  // Parse out key=value pairs first
  const keyValueMatches = [
    ...allParams.matchAll(/([a-z]+)(?:=("[^"]*"|[^\s"]+))?/g),
  ]
  for (const [, key, value] of keyValueMatches) {
    let cleanValue = value ? value.replace(/^"|"$/g, '') : true

    if (key === 'rails') params.rails = cleanValue as string
    if (key === 'core') params.core = cleanValue as string
    if (key === 'description') params.description = cleanValue as string
  }

  return params
}

export function availableSinceMarkdownPlugin(md: MarkdownIt) {
  md.block.ruler.before(
    'paragraph',
    'available_since_oneliner',
    (state, start, end, silent) => {
      const line = state.getLines(start, start + 1, 0, false).trim()

      const match = line.match(/^@available_since\s+(.+)$/)
      if (!match) return false

      if (silent) return true

      const params = parseAvailableSinceParams(`available_since ${match[1]}`)
      const token = state.push('available_since_oneliner', '', 0)

      token.content = renderAvailableSince(params, md)
      token.map = [start, start + 1]

      state.line = start + 1
      return true
    },
  )

  // Render the one-liner available_since token
  md.renderer.rules.available_since_oneliner = (tokens, idx) => {
    return tokens[idx].content + '\n'
  }
}

function renderAvailableSince(
  params: AvailableSinceParams,
  md: MarkdownIt,
): string {
  const railsAttr = params.rails
    ? `rails="${md.utils.escapeHtml(params.rails)}"`
    : ''
  const coreAttr = params.core
    ? `core="${md.utils.escapeHtml(params.core)}"`
    : ''
  const descriptionAttr = params.description
    ? `description="${md.utils.escapeHtml(params.description)}"`
    : ''

  return `<AvailableSince ${railsAttr} ${coreAttr} ${descriptionAttr} />`
}
