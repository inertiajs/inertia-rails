require_relative "middleware"
require_relative "controller"

module InertiaRails
  class Engine < ::Rails::Engine
    initializer "inertia_rails.configure_rails_initialization" do |app|
      app.middleware.use ::InertiaRails::Middleware
    end

    initializer "inertia_rails.action_controller" do
      ActiveSupport.on_load(:action_controller_base) do
        include ::InertiaRails::Controller
      end
    end

    initializer "inertia_rails.subscribe_to_notifications" do
      if Rails.env.development? || Rails.env.test?
        ActiveSupport::Notifications.subscribe('inertia_rails.unoptimized_partial_render') do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)

          message =
            "InertiaRails: The \"#{event.payload[:paths].join(', ')}\" " \
          "prop(s) were excluded in a partial reload but still evaluated because they are defined as values. " \
          "Consider wrapping them in something callable like a lambda."

          Rails.logger.debug(message)
        end
      end
    end
  end
end
