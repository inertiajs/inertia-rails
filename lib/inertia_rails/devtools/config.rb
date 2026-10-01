# frozen_string_literal: true

module InertiaRails
  module Devtools
    class Config
      DEFAULTS = {
        enabled: nil,
        except: [].freeze,

        storage_path: 'tmp/inertia-devtools',
        ttl: 24,
        limit: 100,

        authorize: nil,
        base_controller: 'ActionController::API',

        redact_keys: %w[
          password password_confirmation current_password
          token authenticity_token access_token refresh_token
          secret client_secret api_key
        ].freeze,
        redact_headers: %w[
          cookie set-cookie authorization proxy-authorization x-xsrf-token x-csrf-token
        ].freeze,

        component_paths: %w[app/frontend/pages app/frontend/Pages app/javascript/pages app/javascript/Pages].freeze,
      }.freeze

      ENV_SETTINGS = %i[enabled storage_path ttl limit].freeze

      attr_accessor(*DEFAULTS.keys)

      def initialize
        DEFAULTS.each { |name, default| public_send(:"#{name}=", default) }
        ENV_SETTINGS.each do |name|
          value = ENV.fetch("INERTIA_DEVTOOLS_#{name.upcase}", nil)
          public_send(:"#{name}=", cast(name, value)) if value
        end
      end

      def enabled?
        enabled.nil? ? Rails.env.development? : enabled
      end

      # Runs the authorize callable in the controller; without one, only development is allowed.
      def allows?(controller)
        return Rails.env.development? unless authorize

        !!controller&.instance_exec(&authorize)
      end

      private

      def cast(name, value)
        case name
        when :ttl then Float(value)
        when :limit then Integer(value, 10)
        when :enabled then %w[true false].include?(value) ? value == 'true' : value
        else value
        end
      end
    end
  end
end
