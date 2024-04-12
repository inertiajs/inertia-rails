class InertiaShareController < ApplicationController
  inertia_share do
    { someGroupsControllerData: true }
  end

  def share_without_name
    sleep 0.5
    render inertia: 'ShareTestComponent'
  end

  def share_without_inertia
    render json: {
      teste: "teste"
    }
  end
end
