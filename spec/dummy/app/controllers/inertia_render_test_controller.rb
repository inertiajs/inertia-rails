class InertiaRenderTestController < ApplicationController
  
  def props
    render inertia: 'TestComponent', props: {
      name: 'Brandon',
      sport: -> { 'hockey' }
    }
  end

  def except_props
    render inertia: 'TestComponent', props: {
      flat: 'flat param',
      optional: InertiaRails.optional('optional param'),
      nested_optional: InertiaRails.optional do
        {
          first: 'first nested optional param',
        }
      end,
      nested: {
        first: 'first nested param',
        second: 'second nested param'
      },
      always: InertiaRails.always('always prop')
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

  def optional_props
    render inertia: 'TestComponent', props: {
      name: 'Brian',
      sport: InertiaRails.optional('basketball'),
      level: InertiaRails.optional do
        'worse than he believes'
      end,
      grit: InertiaRails.optional(->{ 'intense' })
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
      sport: InertiaRails.defer('basketball', group: 'other'),
      level: InertiaRails.defer do
        'worse than he believes'
      end,
      grit: InertiaRails.defer(->{ 'intense' })
    }
  end
end
