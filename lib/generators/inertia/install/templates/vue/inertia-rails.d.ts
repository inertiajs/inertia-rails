// See https://inertia-rails.dev/cookbook/handling-validation-error-types.md
import type { FormDataConvertible, FormDataKeys } from '@inertiajs/core'
import type { InertiaFormProps as OriginalProps } from '@inertiajs/vue3'

type FormDataType = Record<string, FormDataConvertible>

declare module '@inertiajs/vue3' {
  interface InertiaFormProps<TForm extends FormDataType>
    extends Omit<OriginalProps<TForm>, 'errors' | 'setError'> {
    errors: Partial<Record<FormDataKeys<TForm>, string[]>>

    setError(field: FormDataKeys<TForm>, value: string[]): this

    setError(errors: Record<FormDataKeys<TForm>, string[]>): this
  }

  export type InertiaForm<TForm extends FormDataType> = TForm &
    InertiaFormProps<TForm>

  export { InertiaFormProps, InertiaForm }

  export function useForm<TForm extends FormDataType>(
    data: TForm | (() => TForm),
  ): InertiaForm<TForm>
  export function useForm<TForm extends FormDataType>(
    rememberKey: string,
    data: TForm | (() => TForm),
  ): InertiaForm<TForm>
}
