import type { InjectionKey, Ref } from 'vue'
import { computed, inject, onMounted, ref } from 'vue'

type TabsSharedState = {
  content?: TabsSharedStateContent
}
type TabsSharedStateContent = Record<string, string>

// Use the same injection key as the original vitepress-plugin-tabs
const injectionKey: InjectionKey<TabsSharedState> =
  'vitepress:tabSharedState' as unknown as symbol
const ls = typeof localStorage !== 'undefined' ? localStorage : null
const localStorageKey = 'vitepress:tabsSharedState'

const getLocalStorageValue = (): TabsSharedStateContent => {
  const rawValue = ls?.getItem(localStorageKey)
  if (rawValue) {
    try {
      return JSON.parse(rawValue)
    } catch {}
  }
  return {}
}

export const useTabsSelectedState = <T extends string>(
  acceptValues: Ref<T[]>,
  sharedStateKey: Ref<string | undefined>,
) => {
  const sharedState = inject(injectionKey)
  if (!sharedState) {
    throw new Error(
      '[vitepress-plugin-tabs] TabsSharedState should be injected',
    )
  }

  onMounted(() => {
    if (!sharedState.content) {
      sharedState.content = getLocalStorageValue()
    }
  })

  const nonSharedState = ref<T | undefined>()

  const selected = computed({
    get() {
      const key = sharedStateKey.value
      const acceptVals = acceptValues.value
      if (key) {
        const value = sharedState.content?.[key]
        if (value && (acceptVals as string[]).includes(value)) {
          return value as T
        }
      } else {
        const nonSharedStateVal = nonSharedState.value
        if (nonSharedStateVal) {
          return nonSharedStateVal
        }
      }
      return acceptVals[0]
    },
    set(v) {
      const key = sharedStateKey.value
      if (key) {
        if (sharedState.content) {
          sharedState.content[key] = v
        }
      } else {
        nonSharedState.value = v
      }
    },
  })

  const select = (newValue: T) => {
    selected.value = newValue
  }

  return { selected, select }
}
