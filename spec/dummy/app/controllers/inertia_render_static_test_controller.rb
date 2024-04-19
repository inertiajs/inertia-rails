class InertiaRenderStaticTestController < ApplicationController
  def static_component
    render inertia: { static: "inertia_render_static_test/custom_view" }
  end

  def default_view
    render inertia: { static: true }
  end
end
