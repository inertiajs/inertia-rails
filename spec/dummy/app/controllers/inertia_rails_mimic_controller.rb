# frozen_string_literal: true

class InertiaRailsMimicController < ApplicationController
  inertia_config(
    default_render: -> { action_name == 'default_render_test' }
  )
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

  def default_component_with_props_test
    render inertia: { my: 'props' }
  end

  def default_component_with_duplicated_props_test
    # should raise an error
    render inertia: { my: 'props' }, props: { another: 'prop' }
  end
end
