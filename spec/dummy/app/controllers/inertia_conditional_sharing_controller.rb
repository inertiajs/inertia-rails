class InertiaConditionalSharingController < ApplicationController
  inertia_share normal_shared_prop: 1

  inertia_share do
    {conditionally_shared_show_prop: 1} if action_name == "show"
  end

  def index
    render inertia: 'EmptyTestComponent', props: {
      index_only_prop: 1,
    }
  end

  def show
    render inertia: 'EmptyTestComponent', props: {
      show_only_prop: 1,
    }
  end
end
