# frozen_string_literal: true

class InertiaDevtoolsTestController < ApplicationController
  inertia_share app_name: 'Dummy'

  def props
    render inertia: 'DevtoolsComponent', props: {
      name: 'Brandon',
      password: 'hunter2',
      ssn: '123-45-6789',
      optional: InertiaRails.optional { 'optional param' },
      deferred: InertiaRails.defer { 'deferred param' },
      items: InertiaRails.merge { [1, 2] },
      nested: { first: 'first nested param' },
      secrets: { token: InertiaRails.always { 'nested secret' } },
    }
  end

  def nested_share
    inertia_share auth: {
      badge: InertiaRails.always { 'A' },
      user: { id: 1, profile: { city: 'Portland' } },
    }

    render inertia: 'DevtoolsComponent', props: { plain_nested: { a: { b: { c: 1 } } } }
  end

  def collection
    render inertia: 'DevtoolsComponent', props: {
      rows: [
        { hidden: InertiaRails.optional { 'never on a first load' } },
        { name: 'first', tag: InertiaRails.always { 'A' } },
        { name: 'second', tag: InertiaRails.always { 'B' } }
      ],
    }
  end

  def oversized
    render inertia: 'DevtoolsComponent', props: { blob: 'x' * 300_000 }
  end

  def plain
    render json: { ok: true, token: 'secret-value' }
  end

  def cached
    fresh_when(etag: 'devtools-stable', public: false)
    return if performed?

    render inertia: 'DevtoolsComponent', props: { name: 'Brandon' }
  end

  def create
    redirect_to devtools_props_path(token: 'leaked')
  end

  def boom
    raise 'devtools boom'
  end
end
