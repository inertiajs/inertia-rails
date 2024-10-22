class InertiaConditionalSharingController < ApplicationController
  before_action :conditionally_share_a_prop, only: :show_with_a_problem

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

  def show_with_a_problem
    render inertia: 'EmptyTestComponent', props: {
      show_only_prop: 1,
    }
  end

  protected

  def conditionally_share_a_prop
    self.class.inertia_share incorrectly_conditionally_shared_prop: 1
  end
end
