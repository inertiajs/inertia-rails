const localStorageKey = 'vitepress:tabsSharedState'
const ls = typeof localStorage !== 'undefined' ? localStorage : null

const getLocalStorageValue = (): Record<string, string> => {
  const rawValue = ls?.getItem(localStorageKey)
  if (rawValue) {
    try {
      return JSON.parse(rawValue)
    } catch {}
  }
  return {}
}

const setLocalStorageValue = (v: Record<string, string>) => {
  if (!ls) return
  ls.setItem(localStorageKey, JSON.stringify(v))
}

export const setupFrameworksTabs = () => {
  const v = getLocalStorageValue()
  if (!v.frameworks) {
    setLocalStorageValue({ frameworks: 'React' })
  }
}
