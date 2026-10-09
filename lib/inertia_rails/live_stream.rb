# frozen_string_literal: true

require 'base64'
require 'openssl'

module InertiaRails
  # Turbo's stream names under an "inertia:" prefix, signed in AnyCable's format for its `$pubsub` channel.
  module LiveStream
    PREFIX = 'inertia'
    EVENT = 'refresh'

    class << self
      # The `live:` option: a streamable, an array naming one stream, or `{ streams: [...] }`.
      def names(live)
        streams =
          if live.is_a?(Hash)
            unless live.keys == [:streams]
              raise ArgumentError, "A `live:` hash only takes `streams:`, got #{live.keys.inspect}"
            end
            unless live[:streams].is_a?(Array) && live[:streams].any?
              raise ArgumentError, '`streams:` must be a non-empty array'
            end

            live[:streams]
          else
            [live]
          end

        streams.map { |streamable| "#{PREFIX}:#{name_part(streamable)}" }
      end

      def option(streamables, streams)
        raise ArgumentError, 'Pass streams as arguments or as `streams:`, not both' if streamables.any? && streams

        streams.nil? ? streamables : { streams: streams }
      end

      def signed(name)
        encoded = Base64.urlsafe_encode64(JSON.dump(name))
        "#{encoded}--#{signature(encoded)}"
      end

      def verified(signed_name)
        return unless signed_name.is_a?(String)

        encoded, _, digest = signed_name.rpartition('--')
        return unless ActiveSupport::SecurityUtils.secure_compare(digest, signature(encoded))

        # With AnyCable, Turbo signs with the same secret; its names are valid here otherwise.
        name = JSON.parse(Base64.urlsafe_decode64(encoded))
        name if name.start_with?("#{PREFIX}:")
      end

      private

      def name_part(streamable)
        case streamable
        when Array
          raise ArgumentError, 'A live stream needs at least one streamable' if streamable.empty?

          streamable.map { |part| name_part(part) }.join(':')
        when nil
          raise ArgumentError, "Can't name a live stream after #{streamable.inspect}"
        else
          streamable.try(:to_gid_param) || streamable.to_param
        end
      end

      def signature(value)
        OpenSSL::HMAC.hexdigest('SHA256', secret, value)
      end

      # Shares AnyCable's secret when there is one, so anycable-go accepts the names we sign.
      def secret
        (AnyCable.config.streams_secret if defined?(AnyCable)) ||
          Rails.application.key_generator.generate_key('inertia_rails/live_streams')
      end
    end
  end
end
