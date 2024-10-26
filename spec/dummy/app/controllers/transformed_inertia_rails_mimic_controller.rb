class TransformedInertiaRailsMimicController < ApplicationController
  inertia_config(
    default_render: true,
  )

  def render_test
  end

  def inertia_render_transformer(path, action)
    "#{path.camelize}/#{action.camelize}"
  end
end
