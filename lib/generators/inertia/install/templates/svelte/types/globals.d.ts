import type { SharedProps } from '@/types'

type windowSvelteType = {
  v: Set<string>;
};

declare global {
  interface Window {
    __svelte: windowSvelteType;
  }
}
declare module '@inertiajs/core' {
  export interface InertiaConfig {
    sharedPageProps: SharedProps
    errorValueType: string[]
  }
}
