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

  def lazy_props
    render inertia: 'TestComponent', props: {
      name: 'Brian',
      sport: InertiaRails.lazy('basketball'),
      level: InertiaRails.lazy do
        'worse than he believes'
      end,
      grit: InertiaRails.lazy(->{ 'intense' })
    }
  end
end
