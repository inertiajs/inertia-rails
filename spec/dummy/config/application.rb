require_relative 'boot'

require "rails"
# Pick the frameworks you want:
# require "active_model/railtie"
# require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
# require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)
require "inertia_rails"

module Dummy
  class Application < Rails::Application
    if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('5.1.0')
      # Initialize configuration defaults for current Rails version.
      config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Required for Rails 5.0 and 5.1
    config.secret_key_base = SecureRandom.hex

    config.exceptions_app = ->(env) do
      Class.new(ActionController::Base) do
        def show
          render inertia: 'Error', props: {
            status: request.path_info[1..-1].to_i
          }
        end
      end.action(:show).call(env)
    end
  end
end
