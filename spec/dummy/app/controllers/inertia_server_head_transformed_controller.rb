# frozen_string_literal: true

class InertiaServerHeadTransformedController < ApplicationController
  inertia_config(
    server_head: true,
    prop_transformer: lambda do |props:|
      props.deep_transform_keys { |key| key.to_s.camelize(:lower) }
    end
  )

  def collision
    inertia_meta.add({ name: 'description', content: 'Inertia rules' })
    render inertia: 'TestComponent', props: { head: 'an unrelated prop' }
  end
end
