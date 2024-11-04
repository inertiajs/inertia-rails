class InertiaUnoptimizedPartialReloadsController < ApplicationController
  inertia_share search: { query: '', results: [] }

  def index
    render inertia: 'TestComponent', props: {
      expensive_prop: expensive_prop,
    }
  end

  def with_multiple
    render inertia: 'TestComponent', props: {
      expensive_prop: expensive_prop,
      another_expensive_prop: "another one",
    }
  end

  def expensive_prop
    'Imagine this is slow to compute'
  end
end
