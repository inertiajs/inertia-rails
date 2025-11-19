import type { SharedProps } from '@/types'

declare module '@inertiajs/core' {
  export interface InertiaConfig {
    sharedPageProps: SharedProps
    errorValueType: string[]
  }
}
