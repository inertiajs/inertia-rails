class InertiaRailsMimicController < ApplicationController
  before_action :enable_inertia_default, only: :default_render_test
  use_inertia_instance_props

  def instance_props_test
    @name = 'Brandon'
    @sport = 'hockey'

    render inertia: 'TestComponent'
  end

  def default_render_test
    @name = 'Brian'
  end

  def provided_props_test
    @name = 'Brian'

    render inertia: 'TestComponent', props: {
      sport: 'basketball',
    }
  end

  def default_component_test
    render inertia: true
  end

  def enable_inertia_default
    InertiaRails.configure do |config|
      config.default_render = true
    end
  end
end
