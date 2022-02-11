<template>
  <h1 :style="{ 'text-align': 'center' }">Hello {{name}}!</h1>
</template>

<script>
export default {
  props: {
    name: { type: String, required: true },
  },
}
</script>
