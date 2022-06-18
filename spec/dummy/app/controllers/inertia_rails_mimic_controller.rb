class InertiaRailsMimicController < ApplicationController
  before_action :enable_inertia_default, only: :default_render_test

  def instance_props_test
    @name = 'Brandon'
    @sport = 'hockey'

    render inertia: 'TestComponent'
  end

  def default_render_test
    @name = 'Brian'
  end

  def default_component_test
    render inertia: nil
  end

  def default_component_shortcut_test
    render_inertia
  end

  def enable_inertia_default
    InertiaRails.configure do |config|
      config.default_render = true
    end
  end
end
