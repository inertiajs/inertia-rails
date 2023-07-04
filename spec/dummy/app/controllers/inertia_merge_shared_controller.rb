class InertiaMergeSharedController < ApplicationController
  inertia_share do
    {
      nested: {
        goals: 100,
        assists: 100,
      }
    }
  end

  def merge_shared
    render inertia: 'ShareTestComponent', props: {
      nested: {
        assists: 200,
      }
    }
  end

  def deep_merge_shared
    render inertia: 'ShareTestComponent', props: {
      nested: {
        assists: 300,
      }
    }, deep_merge: true
  end

  def shallow_merge_shared
    render inertia: 'ShareTestComponent', props: {
      nested: {
        assists: 200,
      }
    }, deep_merge: false
  end
end
