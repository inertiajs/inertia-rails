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
end
