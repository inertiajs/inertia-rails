# frozen_string_literal: true

class InertiaMergeInstancePropsController < ApplicationController
  use_inertia_instance_props
  inertia_share do
    {
      nested: {
        points: 55,
        rebounds: 10,
      },
    }
  end

  def merge_instance_props
    @nested = {
      points: 100,
    }

    render inertia: 'InertiaTestComponent', deep_merge: true
  end
end
