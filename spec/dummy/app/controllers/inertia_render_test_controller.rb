class InertiaRenderTestController < ApplicationController
  
  def props
    render inertia: 'TestComponent', props: {
      name: 'Brandon',
      sport: -> { 'hockey' }
    }
  end

  def view_data
    render inertia: 'TestComponent', view_data: {
      name: 'Brian',
      sport: 'basketball',
    }
  end

  def component
    render inertia: 'TestComponent'
  end
end
