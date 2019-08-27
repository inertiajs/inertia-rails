module Inertia
  class Railtie < Rails::Railtie
    initializer "inertia.configure_rails_initialization" do
      app.middleware.use Inertia::Middleware
    end

    initializer "inertia.action_controller" do
      ActiveSupport.on_load(:action_controller) do
        include Inertia::Controller
      end
    end

    initializer 'inertia.autoload', :before => :set_autoload_paths do |app|
      app.config.autoload_paths << Inertia::Configuration.path
    end

    config.after_initialize do
      require 'inertia/renderer'
      require 'action_controller/metal/renderers'

      ActionController::Renderers.add :inertia do |component, options|
        Inertia::Renderer.new(component, props: options[:props], view_data: options[:view_data]).render
      end
    end
  end
end
