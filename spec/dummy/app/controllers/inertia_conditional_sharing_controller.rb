class InertiaConditionalSharingController < ApplicationController
  before_action :conditionally_share_props, only: [:show]
  inertia_share normal_shared_prop: 1

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

  protected

  def conditionally_share_props
    self.class.inertia_share conditionally_shared_show_prop: 1
  end
end
