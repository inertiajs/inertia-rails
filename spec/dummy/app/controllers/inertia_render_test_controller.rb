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

  def always_props
    render inertia: 'TestComponent', props: {
      always: InertiaRails.always('always prop'),
      regular: 'regular prop',
      optional: InertiaRails.optional do
        'optional prop'
      end,
      another_optional: InertiaRails.optional(->{ 'another optional prop' })
    }
  end

  def merge_props
    render inertia: 'TestComponent', props: {
      merge: InertiaRails.merge('merge prop'),
      regular: 'regular prop',
      deferred_merge: InertiaRails.defer('deferred and merge prop').merge,
      deferred: InertiaRails.defer('deferred'),
    }
  end

  def deferred_props
    render inertia: 'TestComponent', props: {
      name: 'Brian',
      sport: InertiaRails.defer('basketball', 'other'),
      level: InertiaRails.defer do
        'worse than he believes'
      end,
      grit: InertiaRails.defer(->{ 'intense' })
    }
  end
end
