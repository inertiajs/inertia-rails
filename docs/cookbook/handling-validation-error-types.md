# Handling Rails validation error types

When using Inertia Rails with TypeScript, you might encounter a mismatch between the way Rails and Inertia handle validation errors.

- Inertia's `useForm` hook expects the `errors` object to have values as single strings (e.g., `"This field is required"`).
- Rails model errors (`model.errors`), however, provide an array of strings for each field (e.g., `["This field is required", "Must be unique"]`).

If you pass `inertia: { errors: user.errors }` directly from a Rails controller, this mismatch will cause a type conflict.

We'll explore two options to resolve this issue.

## Option 1: Adjust Inertia types

You can update the TypeScript definitions to match the Rails error format (arrays of strings).

Create a custom type definition file in your project:

:::tabs key:frameworks
== Vue

```typescript
// frontend/app/types/inertia-rails.d.ts
import type { FormDataConvertible, FormDataKeys } from '@inertiajs/core'
import type { InertiaFormProps as OriginalProps } from '@inertiajs/vue3'

type FormDataType = Record<string, FormDataConvertible>

declare module '@inertiajs/vue3' {
  interface InertiaFormProps<TForm extends FormDataType> extends Omit<
    OriginalProps<TForm>,
    'errors' | 'setError'
  > {
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
```

== React

```typescript
// frontend/app/types/inertia-rails.d.ts
import type { FormDataConvertible, FormDataKeys } from '@inertiajs/core'
import type { InertiaFormProps as OriginalProps } from '@inertiajs/react'

type FormDataType = Record<string, FormDataConvertible>

declare module '@inertiajs/react' {
  interface InertiaFormProps<TForm extends FormDataType> extends Omit<
    OriginalProps<TForm>,
    'errors' | 'setError'
  > {
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
```

== Svelte 4|Svelte 5

```typescript
// frontend/app/types/inertia-rails.d.ts
import type { FormDataConvertible, FormDataKeys } from '@inertiajs/core'
import type { InertiaFormProps as OriginalProps } from '@inertiajs/svelte'
import type { Writable } from 'svelte/store'

type FormDataType = Record<string, FormDataConvertible>

declare module '@inertiajs/svelte' {
  interface InertiaFormProps<TForm extends FormDataType> extends Omit<
    OriginalProps<TForm>,
    'errors' | 'setError'
  > {
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
```

:::

This tells TypeScript to expect errors as arrays of strings, matching Rails' format.

> [!NOTE]
> Make sure that `d.ts` files are referenced in your `tsconfig.json` or `tsconfig.app.json`. If it reads something like `"include": ["app/frontend/**/*.ts"]` or `"include": ["app/frontend/**/*"]` and your `d.ts` file is inside `app/frontend`, it should work.

## Option 2: Serialize errors in Rails

You can add a helper on the Rails backend to convert error arrays into single strings before sending them to Inertia.

1. Add a helper method (e.g., in `ApplicationController`):

   ```ruby
   def inertia_errors(model)
     {
       errors: model.errors.to_hash(true).transform_values(&:to_sentence)
     }
   end
   ```

   This combines multiple error messages for each field into a single string.

2. Use the helper when redirecting with errors:

   ```ruby
   redirect_back inertia: inertia_errors(model)
   ```

This ensures the errors sent to the frontend are single strings, matching Inertia's default expectations.
