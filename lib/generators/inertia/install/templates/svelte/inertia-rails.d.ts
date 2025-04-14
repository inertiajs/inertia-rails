// See https://inertia-rails.dev/cookbook/handling-validation-error-types.md
import type { FormDataConvertible, FormDataKeys } from '@inertiajs/core'
import type { InertiaFormProps as OriginalProps } from '@inertiajs/svelte'
import type { Writable } from 'svelte/store'

type FormDataType = Record<string, FormDataConvertible>

declare module '@inertiajs/svelte' {
  interface InertiaFormProps<TForm extends FormDataType>
    extends Omit<OriginalProps<TForm>, 'errors' | 'setError'> {
    errors: Partial<Record<FormDataKeys<TForm>, string[]>>

    setError(field: FormDataKeys<TForm>, value: string[]): this

    setError(errors: Record<FormDataKeys<TForm>, string[]>): this
  }

  type InertiaForm<TForm extends FormDataType> = InertiaFormProps<TForm> & TForm

  export { InertiaFormProps, InertiaForm }

  export function useForm<TForm extends FormDataType>(
    data: TForm | (() => TForm),
  ): Writable<InertiaForm<TForm>>
  export function useForm<TForm extends FormDataType>(
    rememberKey: string,
    data: TForm | (() => TForm),
  ): Writable<InertiaForm<TForm>>
}
