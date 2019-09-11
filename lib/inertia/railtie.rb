require_relative "middleware"
#require_relative "controller"
#require_relative "inertia"

module Inertia
  class Railtie < ::Rails::Railtie
    initializer "inertia.configure_rails_initialization" do |app|
      app.middleware.use Middleware
    end

    #initializer "inertia.action_controller" do
      #ActiveSupport.on_load(:action_controller) do
        #include Controller
      #end
    #end

    #initializer 'inertia.autoload', :before => :set_autoload_paths do |app|
      #app.config.autoload_paths << File.expand_path("./inertia.rb", __FILE__)
    #end

  end
end
