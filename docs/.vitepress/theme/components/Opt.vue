<script setup lang="ts">
import { computed, ref } from 'vue'
import { useTabsSelectedState } from '../composables/useTabsSelectedState'

const props = defineProps<{
  v: string
}>()

// Use the shared tabs state system
const acceptValues = ref(['Vue', 'React', 'Svelte 4', 'Svelte 5'])
const sharedStateKey = ref('frameworks')

const { selected } = useTabsSelectedState(acceptValues, sharedStateKey)

const shouldShow = computed(() => {
  if (!selected.value) return false

  // Handle multiple values separated by pipe (|)
  const values = props.v.split('|').map((v) => v.trim())
  return values.includes(selected.value)
})
</script>

<template>
  <span v-if="shouldShow" class="opt-text">
    <slot></slot>
  </span>
</template>

<style scoped>
.opt-text {
  display: inline;
}
</style>
