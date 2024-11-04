class InertiaHasSearchableController < ApplicationController
  include Searchable

  def index
    render inertia: 'TestComponent', props: {
      unrequested_prop: 'This will always compute even when not requested in a partial reload',
    }
  end
end
