class TransformedInertiaRailsMimicController < ApplicationController
  inertia_config(
    default_render: true,
    component_path_resolver: ->(path:, action:) do
      "#{path.camelize}/#{action.camelize}"
    end
  )

  def render_test
  end
end
