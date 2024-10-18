class InertiaConditionalSharingController < ApplicationController
  before_action :conditionally_share_a_prop, only: :show_with_a_problem

  inertia_share normal_shared_prop: 1

  inertia_share do
    {conditionally_shared_show_prop: 1} if action_name == "show"
  end

  inertia_share only: :edit do
    {only_block_prop: 1}
  end

  inertia_share except: [:show, :index] do
    {except_block_prop: 1}
  end

  inertia_share if: -> { is_edit? } do
    {if_proc_prop: 1}
  end

  inertia_share unless: -> { !is_edit? } do
    {unless_proc_prop: 1}
  end

  inertia_share({only_prop: 1}, only: :edit)

  inertia_share({if_prop: 1}, if: [:is_edit?, -> { true }])

  inertia_share({unless_prop: 1}, unless: :not_edit?)

  inertia_share({only_if_prop: 1}, only: :edit, if: -> { true })

  inertia_share({except_if_prop: 1}, except: [:index, :show], if: -> { true })

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

  def edit
    render inertia: 'EmptyTestComponent', props: {
      edit_only_prop: 1,
    }
  end

  protected

  def conditionally_share_a_prop
    self.class.inertia_share incorrectly_conditionally_shared_prop: 1
  end

  def not_edit?
    !is_edit?
  end

  def is_edit?
    action_name == "edit"
  end
end
