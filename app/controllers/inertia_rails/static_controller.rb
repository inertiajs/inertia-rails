module InertiaRails
  class StaticController < InertiaRails.configuration.parent_controller.constantize
    def static
      respond_to do |format|
        format.html { render inertia: params[:component] }
      end
    end
  end
end
