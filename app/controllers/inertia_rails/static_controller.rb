module InertiaRails
  class StaticController < InertiaRails.configuration.parent_controller.constantize
    def static
      render inertia: params[:component]
    end
  end
end
