# frozen_string_literal: true

# Derived from turbo-rails (MIT licensed, Copyright Basecamp).
# https://github.com/hotwired/turbo-rails

module InertiaRails
  module Broadcast
    BROADCAST_TYPE = { remove: 'destroy', replace: 'update' }.freeze

    class << self
      def action_to(streamable, record:, action:, serializer: nil, request_id: nil)
        stream_name = StreamName.stream_name_from(streamable)
        id = record.try(:id)
        type = BROADCAST_TYPE.fetch(action.to_sym, action.to_s)

        message = { type: type, id: id }
        message[:value] = serialize_for_broadcast(record, serializer) unless action.to_sym == :remove

        message[:request_id] = request_id if request_id
        ActionCable.server.broadcast(stream_name, message)
      end

      def refresh_to(streamable, request_id: nil)
        stream_name = StreamName.stream_name_from(streamable)
        message = { type: 'reload' }
        message[:request_id] = request_id if request_id
        ActionCable.server.broadcast(stream_name, message)
      end

      def to(streamable, record: nil, action: nil, **options)
        if record && action
          InertiaRails.broadcast_action_to(streamable, record: record, action: action, **options)
        else
          InertiaRails.broadcast_refresh_to(streamable, **options.slice(:request_id))
        end
      end

      private

      def serialize_for_broadcast(record, serializer)
        if serializer
          serializer.is_a?(Class) ? serializer.new(record).to_h : serializer.call(record)
        elsif (fallback = InertiaRails.configuration.broadcast_serializer)
          fallback.call(record)
        else
          record.as_json
        end
      end
    end
  end
end
