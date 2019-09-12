require_relative "middleware"
require_relative "controller"

module Inertia
  class Engine < ::Rails::Engine
    initializer "inertia.configure_rails_initialization" do |app|
      app.middleware.use ::Inertia::Middleware
    end

    initializer "inertia.action_controller" do
      ActiveSupport.on_load(:action_controller) do
        include ::Inertia::Controller
      end
    end
  end
end
