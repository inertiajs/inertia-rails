class InertiaUnoptimizedPartialReloadsController < ApplicationController
  inertia_share search: { query: '', results: [] }

  def index
    render inertia: 'TestComponent', props: {
      expensive_prop: expensive_prop,
    }
  end

  def with_exception
    render inertia: 'TestComponent', props: {
      expensive_prop: expensive_prop,
    }
  end

  def expensive_prop
    'Imagine this is slow to compute'
  end
end
