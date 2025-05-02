class InertiaSharedMetaController < ApplicationController
  before_action :conditionally_share_meta, only: :show_with_a_problem

  # Plain data
  inertia_meta [
    { tag_name: 'title', inner_content: 'The Inertia Title', head_key: '1' },
    { name: 'description', content: 'non-conditional plain data', head_key: '2' },
  ]

  # Callable
  inertia_meta do
    [
      { name: 'description', content: 'non-conditional callable data', head_key: '3' },
      { name: 'description', content: 'second non-conditional callable data', head_key: '4' },
    ]
  end

  # Conditional Plain data
  inertia_meta([{ name: 'description', content: 'conditional plain data, only edit', head_key: '5' }], only: :edit)
  inertia_meta([{ name: 'description', content: 'conditional plain data, if edit, with multiple conditions', head_key: '6' }], if: [:is_edit?, -> { true }])
  inertia_meta([{ name: 'description', content: 'conditional plain data, unless not_edit with a method reference', head_key: '7' }], unless: :not_edit?)
  inertia_meta([{ name: 'description', content: 'conditional plain data, with only edit and an if option', head_key: '8' }], only: :edit, if: -> { true })
  inertia_meta([{ name: 'description', content: 'conditional plain data, except index and show, with an if option', head_key: '9' }], except: [:index, :show], if: -> { true })

  # Conditional Callables
  inertia_meta only: :edit do
    [{name: 'description', content: 'conditional callable data, only edit', head_key: '10' }]
  end

  inertia_meta except: [:show, :index] do
    [{name: 'description', content: 'conditional callable data, except show and index', head_key: '11' }]
  end

  inertia_meta if: -> { is_edit? } do
    [{name: 'description', content: 'conditional callable data, if is_edit?', head_key: '12'}]
  end

  inertia_meta unless: -> { !is_edit? } do
    [{name: 'description', content: 'conditional callable data, unless !is_edit?', head_key: '13'}]
  end

  inertia_meta do
    [].tap do |a|
      if is_edit?
        a << {name: 'description', content: 'instance_exec lets you conditionally add data as well', head_key: '14'}
      end
    end
  end

  def index
    render inertia: 'EmptyTestComponent', meta: [{ name: 'description', content: 'index renderer', head_key: 'index' }]
  end

  def show
    render inertia: 'EmptyTestComponent', meta: []
  end

  def edit
    render inertia: 'EmptyTestComponent', meta: []
  end

  def show_with_a_problem
    render inertia: 'EmptyTestComponent'
  end

  protected

  def is_edit?
    action_name == 'edit'
  end

  def not_edit?
    !is_edit?
  end

  def conditionally_share_meta
    self.class.inertia_meta [
      { name: 'description', content: 'badly shared meta' },
    ]
  end
end
