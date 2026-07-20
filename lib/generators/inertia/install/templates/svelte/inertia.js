import { createInertiaApp } from '@inertiajs/svelte'

createInertiaApp({
  pages: "../pages",

  serverHead: true,

  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: false,
      withAllErrors: true,
    },
    visitOptions: () => {
      return { queryStringArrayFormat: "brackets" }
    },
  },
})
