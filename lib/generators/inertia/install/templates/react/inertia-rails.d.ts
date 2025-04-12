// See https://inertia-rails.dev/cookbook/handling-validation-error-types.md
import type { FormDataConvertible, FormDataKeys } from '@inertiajs/core'
import type { InertiaFormProps as OriginalProps } from '@inertiajs/react'

type FormDataType = Record<string, FormDataConvertible>

declare module '@inertiajs/react' {
  interface InertiaFormProps<TForm extends FormDataType>
    extends Omit<OriginalProps<TForm>, 'errors' | 'setError'> {
    errors: Partial<Record<FormDataKeys<TForm>, string[]>>

    setError(field: FormDataKeys<TForm>, value: string[]): void

    setError(errors: Record<FormDataKeys<TForm>, string[]>): void
  }

  export { InertiaFormProps }

  export function useForm<TForm extends FormDataType>(
    initialValues?: TForm,
  ): InertiaFormProps<TForm>
  export function useForm<TForm extends FormDataType>(
    rememberKey: string,
    initialValues?: TForm,
  ): InertiaFormProps<TForm>
}
