# frozen_string_literal: true

module InertiaRails
  class StaticController < InertiaRails.configuration.parent_controller.constantize
    def static
      # Checked at dispatch, not load: eager loading defines this class even
      # in apps that never draw an `inertia` route, and those must still boot.
      unless is_a?(::ActionController::Base)
        raise ArgumentError,
              '`config.parent_controller` must inherit from ActionController::Base to serve `inertia` routes, ' \
              "got #{InertiaRails.configuration.parent_controller.inspect}"
      end

      respond_to do |format|
        format.html { render inertia: params[:component] }
      end
    end
  end
end
