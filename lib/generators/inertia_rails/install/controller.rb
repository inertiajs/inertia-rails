class InertiaExampleController < ApplicationController
  def index
    render inertia: 'InertiaExample', props: {
      name: 'World',
    }
  end
end
