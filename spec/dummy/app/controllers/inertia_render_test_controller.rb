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
      optional: InertiaRails.optional { 'optional param' },
      nested_optional: InertiaRails.optional do
        {
          first: 'first nested optional param',
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
    response.headers['Vary'] = 'Accept-Language'

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

  def optional_props
    render inertia: 'TestComponent', props: {
      regular: 1,
      optional: InertiaRails.optional { 1 },
      another_optional: InertiaRails.optional { 1 },
    }
  end

  def always_props
    render inertia: 'TestComponent', props: {
      always: InertiaRails.always { 'always prop' },
      regular: 'regular prop',
      optional: InertiaRails.optional do
        'optional prop'
      end,
      another_optional: InertiaRails.optional { 'another optional prop' }
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
