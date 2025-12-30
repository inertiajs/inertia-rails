# frozen_string_literal: true

require_relative 'middleware'
require_relative 'controller'
require_relative 'flash_extension'

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

    initializer 'inertia_rails.flash_extension' do
      ActionDispatch::Flash::FlashHash.prepend ::InertiaRails::FlashExtension
      ActionDispatch::Flash::FlashNow.prepend ::InertiaRails::FlashExtension
    end
  end
end
