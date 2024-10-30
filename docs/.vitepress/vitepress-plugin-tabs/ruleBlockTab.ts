import type { RuleBlock } from 'markdown-it/lib/parser_block'

const tabMarker = '='
const tabMarkerCode = tabMarker.charCodeAt(0)
const minTabMarkerLen = 2

export const ruleBlockTab: RuleBlock = (state, startLine, endLine, silent) => {
  let pos = state.bMarks[startLine] + state.tShift[startLine]
  const max = state.eMarks[startLine]

  // @ts-expect-error markdown-it-container uses 'container'
  if (state.parentType !== 'container') {
    return false
  }

  if (pos + minTabMarkerLen > max) {
    return false
  }

  const marker = state.src.charCodeAt(pos)
  if (marker !== tabMarkerCode) {
    return false
  }

  // scan marker length
  const mem = pos
  pos = state.skipChars(pos + 1, marker)
  const tabMarkerLen = pos - mem

  if (tabMarkerLen < minTabMarkerLen - 1) {
    return false
  }

  // for validation mode
  if (silent) {
    return true
  }

  // search for the end of the block
  let nextLine = startLine
  let endStart = mem
  let endPos = pos

  for (;;) {
    nextLine++
    if (nextLine >= endLine) {
      break // unclosed block is autoclosed
    }

    endStart = state.bMarks[nextLine] + state.tShift[nextLine]
    const max = state.eMarks[nextLine]

    if (endStart < max && state.sCount[nextLine] < state.blkIndent) {
      // non-empty line with negative indent should stop the list:
      // - ```
      //  test
      break
    }

    const startCharCode = state.src.charCodeAt(endStart)
    if (startCharCode !== tabMarkerCode) {
      continue
    }

    const p = state.skipChars(endStart + 1, marker)
    if (p - endStart !== tabMarkerLen) {
      continue
    }
    endPos = p
    break
  }

  const oldParent = state.parentType
  const oldLineMax = state.lineMax
  // @ts-expect-error use 'tab' for this rule
  state.parentType = 'tab'
  // this will prevent lazy continuations from ever going past our end marker
  state.lineMax = nextLine

  state.src
    .slice(pos, max)
    .trimStart()
    .split('|')
    .forEach((label) => {
      const startToken = state.push('tab_open', 'div', 1)
      startToken.markup = state.src.slice(mem, pos)
      startToken.block = true
      startToken.info = label
      startToken.map = [startLine, nextLine - 1]

      state.md.block.tokenize(state, startLine + 1, nextLine)

      const endToken = state.push('tab_close', 'div', -1)
      endToken.markup = state.src.slice(endStart, endPos)
      endToken.block = true
    })

  state.parentType = oldParent
  state.lineMax = oldLineMax
  state.line = nextLine
  return true
}
