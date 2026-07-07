# frozen_string_literal: true

# Derived from turbo-rails (MIT licensed, Copyright Basecamp).
# https://github.com/hotwired/turbo-rails

module InertiaRails
  # Wire protocol v1: signals carry facts, never values. There is no
  # serializer and no payload — clients refetch through the normal Inertia
  # HTTP pipeline (re-authorized, re-scoped), or apply destroy signals
  # locally when the prop opted in via +on_destroy+.
  module Broadcast
    PROTOCOL = 1

    REQUEST_ID_HEADER = 'X-Inertia-Live-Request-Id'

    ACTIONS = %i[create update destroy].freeze

    class << self
      # Broadcasts a record lifecycle fact: {type:, model:, id:, request_id:}.
      # +action+ is the ActiveRecord event (:create/:update/:destroy) — a fact
      # about the record, not an instruction to the client.
      def change_to(streamable, record:, action:, request_id: nil)
        unless ACTIONS.include?(action.to_sym)
          raise ArgumentError, "Unknown broadcast action #{action.inspect} (expected one of #{ACTIONS.inspect})"
        end

        message = {
          type: action.to_s,
          model: record.model_name.name,
          id: record.id,
          request_id: request_id,
        }.compact

        ActionCable.server.broadcast(StreamName.stream_name_from(streamable), message)
      end

      # Broadcasts a bare "reload your props" signal: {type: "reload", request_id:}.
      def refresh_to(streamable, request_id: nil)
        message = { type: 'reload', request_id: request_id }.compact
        ActionCable.server.broadcast(StreamName.stream_name_from(streamable), message)
      end
    end
  end
end
