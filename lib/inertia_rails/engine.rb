# frozen_string_literal: true

module InertiaRails
  class Engine < ::Rails::Engine
    initializer 'inertia_rails.configure_rails_initialization' do |app|
      app.middleware.use ::InertiaRails::Middleware
    end

    initializer 'inertia_rails.action_controller' do
      ActiveSupport.on_load(:action_controller_base) do
        include ::InertiaRails::Controller
      end
    end

    initializer 'inertia_rails.renderer' do
      ActiveSupport.on_load(:action_controller) do
        ActionController::Renderers.add :inertia do |component, options|
          InertiaRails::Renderer.new(
            component,
            self,
            request,
            response,
            method(:render),
            **options
          ).render
        end
      end
    end

    initializer 'inertia_rails.flash_extension' do
      ActionDispatch::Flash::FlashHash.prepend ::InertiaRails::FlashExtension
      ActionDispatch::Flash::FlashNow.prepend ::InertiaRails::FlashExtension
    end

    initializer 'inertia_rails.request' do
      require_relative 'extensions/request'
      ActionDispatch::Request.include ::InertiaRails::InertiaRequest
    end

    initializer 'inertia_rails.mapper' do
      require_relative 'extensions/mapper'
      ActionDispatch::Routing::Mapper.include ::InertiaRails::InertiaMapper
    end

    initializer 'inertia_rails.debug_exceptions' do
      require_relative 'extensions/debug_exceptions'
      if defined?(ActionDispatch::DebugExceptions)
        ActionDispatch::DebugExceptions.prepend ::InertiaRails::InertiaDebugExceptions
      end
    end

    initializer 'inertia_rails.better_errors' do
      require_relative 'extensions/better_errors'
      BetterErrors::Middleware.include ::InertiaRails::InertiaBetterErrors if defined?(BetterErrors::Middleware)
    end
  end
end
