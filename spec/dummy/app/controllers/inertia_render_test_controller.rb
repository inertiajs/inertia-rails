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
      lazy: InertiaRails.lazy('lazy param'),
      nested_lazy: InertiaRails.lazy do
        {
          first: 'first nested lazy param',
        }
      end,
      nested: {
        first: 'first nested param',
        second: 'second nested param'
      },
      always: InertiaRails.always { 'always prop' }
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

  def vary_header
    response.headers["Vary"] = 'Accept-Language'

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
      always: InertiaRails.always { 'always prop' },
      regular: 'regular prop',
      lazy: InertiaRails.lazy do
        'lazy prop'
      end,
      another_lazy: InertiaRails.lazy(->{ 'another lazy prop' })
    }
  end

  def merge_props
    render inertia: 'TestComponent', props: {
      merge: InertiaRails.merge { 'merge prop' },
      regular: 'regular prop',
      deferred_merge: InertiaRails.defer(merge: true) { 'deferred and merge prop'},
      deferred: InertiaRails.defer { 'deferred' },
    }
  end

  def deferred_props
    render inertia: 'TestComponent', props: {
      name: 'Brian',
      sport: InertiaRails.defer(group: 'other') { 'basketball' },
      level: InertiaRails.defer do
        'worse than he believes'
      end,
      grit: InertiaRails.defer { 'intense' }
    }
  end
end
