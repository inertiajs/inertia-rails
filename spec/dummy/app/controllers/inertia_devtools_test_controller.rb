# frozen_string_literal: true

class InertiaDevtoolsTestController < ApplicationController
  inertia_share app_name: 'Dummy'

  def props
    render inertia: 'DevtoolsComponent', props: {
      name: 'Brandon',
      password: 'hunter2',
      optional: InertiaRails.optional { 'optional param' },
      deferred: InertiaRails.defer { 'deferred param' },
      items: InertiaRails.merge { [1, 2] },
      nested: { first: 'first nested param' },
    }
  end

  def plain
    render json: { ok: true, token: 'secret-value' }
  end

  def create
    redirect_to devtools_props_path
  end
end
