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

  def deeply_nested_props
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
        second: 'second nested param',
        evaluated: -> do
          {
            first: 'first evaluated nested param',
            second: 'second evaluated nested param'
          }
        end,
        deeply_nested: {
          first: 'first deeply nested param',
          second: false,
          what_about_nil: nil,
          what_about_empty_hash: {},
          deeply_nested_always: InertiaRails.always { 'deeply nested always prop' },
          deeply_nested_lazy: InertiaRails.lazy { 'deeply nested lazy prop' }
        }
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
      deferred_merge: InertiaRails.defer(merge: true) { 'deferred and merge prop' },
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
