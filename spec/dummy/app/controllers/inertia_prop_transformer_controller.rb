# frozen_string_literal: true

class InertiaPropTransformerController < ApplicationController
  inertia_config(
    prop_transformer: lambda do |props:|
      props.deep_transform_keys { |key| key.to_s.upcase }
    end
  )

  def just_props
    render inertia: 'TestComponent', props: {
      lower_prop: 'lower_value',
      parent_hash: {
        lower_child_prop: 'lower_child_value',
      },
    }
  end

  def props_and_meta
    render inertia: 'TestComponent',
           props: {
             lower_prop: 'lower_value',
           },
           meta: [
             { name: 'description', content: "Don't transform me!" }
           ]
  end

  def no_props
    render inertia: 'TestComponent'
  end
end
