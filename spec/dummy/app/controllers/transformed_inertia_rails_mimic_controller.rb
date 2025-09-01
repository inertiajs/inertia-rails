# frozen_string_literal: true

class TransformedInertiaRailsMimicController < ApplicationController
  inertia_config(
    default_render: true,
    component_path_resolver: lambda do |path:, action:|
      "#{path.camelize}/#{action.camelize}"
    end
  )

  def render_test; end
end
