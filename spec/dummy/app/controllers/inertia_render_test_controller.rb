# frozen_string_literal: true

class InertiaRenderTestController < ApplicationController
  def props
    render inertia: 'TestComponent', props: {
      name: 'Brandon',
      sport: -> { 'hockey' },
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
        second: 'second nested param',
      },
      always: InertiaRails.always { 'always prop' },
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
        evaluated: lambda do
          {
            first: 'first evaluated nested param',
            second: 'second evaluated nested param',
          }
        end,
        deeply_nested: {
          first: 'first deeply nested param',
          second: false,
          what_about_nil: nil,
          what_about_empty_hash: {},
          deeply_nested_always: InertiaRails.always { 'deeply nested always prop' },
          deeply_nested_lazy: InertiaRails.lazy { 'deeply nested lazy prop' },
        },
      },
      always: InertiaRails.always { 'always prop' },
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
      grit: InertiaRails.lazy(-> { 'intense' }),
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
      another_optional: InertiaRails.optional { 'another optional prop' },
    }
  end

  def merge_props
    render inertia: 'TestComponent', props: {
      merge: InertiaRails.merge { 'merge prop' },
      match_on: InertiaRails.merge(match_on: 'id') { [id: 1] },
      deep_merge: InertiaRails.deep_merge { { deep: 'merge prop' } },
      deep_match_on: InertiaRails.deep_merge(match_on: 'deep.id') { { deep: [id: 1] } },
      regular: 'regular prop',
      deferred_merge: InertiaRails.defer(merge: true) { 'deferred and merge prop' },
      deferred_match_on: InertiaRails.defer(merge: true, match_on: 'id') { [id: 1] },
      deferred_deep_merge: InertiaRails.defer(deep_merge: true) { { deep: 'deferred and merge prop' } },
      deferred_deep_match_on: InertiaRails.defer(deep_merge: true, match_on: 'deep.id') { { deep: [id: 1] } },
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
      grit: InertiaRails.defer { 'intense' },
    }
  end

  inertia_share only: [:shared_deferred_props] do
    {
      grit: InertiaRails.defer { 'intense' },
    }
  end
  def shared_deferred_props
    render inertia: 'TestComponent', props: {
      name: 'Brian',
    }
  end

  def scroll_test
    pagy = (defined?(Pagy::Offset) ? Pagy::Offset : Pagy).new(
      next: 2,
      page: 1,
      count: 100
    )

    render inertia: 'TestComponent', props: {
      users: InertiaRails.scroll(pagy) { [{ id: 1, name: 'User 1' }, { id: 2, name: 'User 2' }] },
    }
  end

  inertia_share only: [:shared_scroll_test] do
    pagy = (defined?(Pagy::Offset) ? Pagy::Offset : Pagy).new(
      next: 2,
      page: 1,
      count: 100
    )
    {
      users: InertiaRails.scroll(pagy) { [{ id: 1, name: 'User 1' }, { id: 2, name: 'User 2' }] },
    }
  end

  def shared_scroll_test
    render inertia: 'TestComponent'
  end

  def prepend_merge_test
    render inertia: 'TestComponent', props: {
      prepend_prop: InertiaRails.merge(prepend: true) { %w[item1 item2] },
      append_prop: InertiaRails.merge { %w[item3 item4] },
    }
  end

  def nested_paths_test
    render inertia: 'TestComponent', props: {
      foo: InertiaRails.merge(append: { data: :id }) { { data: [{ id: 1 }, { id: 2 }] } },
      bar: InertiaRails.merge(prepend: { 'data.items' => 'uuid' }) do
        { data: { items: [{ uuid: 1 }, { uuid: 2 }] } }
      end,
    }
  end

  def reset_test
    render inertia: 'TestComponent', props: {
      merge_prop: InertiaRails.merge { 'merge value' },
      regular_prop: 'regular value',
    }
  end
end
