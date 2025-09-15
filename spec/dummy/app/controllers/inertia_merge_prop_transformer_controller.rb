# frozen_string_literal: true

class InertiaMergePropTransformerController < ApplicationController
  inertia_config(
    merge_prop_transformer: lambda do |merge_props:|
      merge_props.map { |prop| prop.to_s.camelize(:lower) }
    end
  )

  def with_merge_props
    render inertia: 'TestComponent', props: {
      snake_case_merge: InertiaRails.merge { 'merge prop' },
      another_snake_merge: InertiaRails.merge(match_on: 'id') { [id: 1] },
      regular_prop: 'regular prop',
    }
  end

  def with_deep_merge_props
    render inertia: 'TestComponent', props: {
      snake_case_deep_merge: InertiaRails.deep_merge { { deep: 'merge prop' } },
      another_snake_deep_merge: InertiaRails.deep_merge(match_on: 'deep.id') { { deep: [id: 1] } },
      regular_prop: 'regular prop',
    }
  end

  def with_both_merge_types
    render inertia: 'TestComponent', props: {
      snake_case_merge: InertiaRails.merge { 'merge prop' },
      snake_case_deep_merge: InertiaRails.deep_merge { { deep: 'merge prop' } },
      regular_prop: 'regular prop',
    }
  end

  def no_merge_props
    render inertia: 'TestComponent', props: {
      regular_prop: 'regular prop',
    }
  end
end
