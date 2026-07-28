# frozen_string_literal: true

module InertiaRails
  class Engine < ::Rails::Engine
    initializer 'inertia_rails.configure_rails_initialization', before: :build_middleware_stack do |app|
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
          # See Controller#_normalize_options — restore the user's original
          # :layout or discard the Rails-injected default.
          if options.key?(:_inertia_layout)
            options[:layout] = options.delete(:_inertia_layout)
          else
            options.delete(:layout)
          end

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

    # Drawn unconditionally — routes are static, so enablement is enforced by the
    # controller instead of by whether the app happened to boot with it on.
    initializer 'inertia_rails.devtools' do |app|
      app.routes.prepend do
        # Left unnamed: these would otherwise claim `entries_path` in the host
        # app's helpers and in anything that generates from the route table.
        scope ::InertiaRails::Devtools::ROUTE_PREFIX, format: false, as: nil do
          get 'entries', to: 'inertia_rails/devtools/entries#index', as: nil
          get 'entries/:id', to: 'inertia_rails/devtools/entries#show', as: nil,
                             constraints: { id: /[0-9A-HJKMNP-TV-Z]{26}/ }
        end
      end
    end

    initializer 'inertia_rails.better_errors' do
      require_relative 'extensions/better_errors'
      BetterErrors::Middleware.include ::InertiaRails::InertiaBetterErrors if defined?(BetterErrors::Middleware)
    end
  end
end
