class TransformedInertiaRailsMimicController < ApplicationController
  inertia_config(
    default_render: true,
    render_transformer: ->(path, action) do
      "#{path.camelize}/#{action.camelize}"
    end
  )

  def render_test
  end
end
