require_relative "middleware"
require_relative "controller"

module InertiaRails
  class Engine < ::Rails::Engine
    initializer "inertia.configure_rails_initialization" do |app|
      app.middleware.use ::InertiaRails::Middleware
    end

    initializer "inertia.action_controller" do
      ActiveSupport.on_load(:action_controller) do
        include ::InertiaRails::Controller
      end
    end
  end
end
