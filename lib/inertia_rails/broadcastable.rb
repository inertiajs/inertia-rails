# frozen_string_literal: true

# Derived from turbo-rails (MIT licensed, Copyright Basecamp).
# https://github.com/hotwired/turbo-rails

module InertiaRails
  module Broadcastable
    extend ActiveSupport::Concern

    ACTION_MAP = { create: :append, update: :replace, destroy: :remove }.freeze

    included do
      thread_mattr_accessor :suppressed_inertia_broadcasts, instance_accessor: false
      delegate :suppressed_inertia_broadcasts?, to: 'self.class'
    end

    class_methods do
      # Configures the model to broadcast surgical updates (append/replace/remove) on create, update,
      # and destroy to the stream name derived from +target+.
      #
      #   class Message < ApplicationRecord
      #     belongs_to :board
      #     broadcasts_to :board
      #   end
      #
      #   class Message < ApplicationRecord
      #     broadcasts_to ->(message) { [message.board, :messages] }, inserts_by: :prepend
      #   end
      def broadcasts_to(target, on: ACTION_MAP.keys, inserts_by: :append, serializer: nil, **options)
        filter_opts = options.slice(:if, :unless)

        Array(on).each do |event|
          action = event == :create ? inserts_by : ACTION_MAP.fetch(event)

          after_commit(on: event, **filter_opts) do
            next if self.class.suppressed_inertia_broadcasts?

            streamable = resolve_broadcastable_target(target)
            InertiaRails.broadcast_action_to(
              streamable,
              record: self,
              action: action,
              serializer: serializer,
              request_id: InertiaRails::Current.live_request_id
            )
          end
        end
      end

      # Configures the model to broadcast a "page refresh" on create, update, and destroy. Refreshes are
      # debounced by default so rapid changes coalesce into a single broadcast. Pass <tt>debounce: false</tt>
      # to disable debouncing.
      #
      #   class Column < ApplicationRecord
      #     broadcasts_refreshes_to :board
      #   end
      def broadcasts_refreshes_to(target, on: %i[create update destroy], debounce: InertiaRails::Debouncer::DEFAULT_DELAY, **options)
        filter_opts = options.slice(:if, :unless)

        Array(on).each do |event|
          after_commit(on: event, **filter_opts) do
            next if self.class.suppressed_inertia_broadcasts?

            streamable = resolve_broadcastable_target(target)
            request_id = InertiaRails::Current.live_request_id

            if debounce
              stream_name = InertiaRails::StreamName.stream_name_from([streamable, request_id].compact)
              InertiaRails::ThreadDebouncer
                .for("inertia_live_debounce:#{stream_name}", delay: debounce)
                .debounce { InertiaRails.broadcast_refresh_to(streamable, request_id: request_id) }
            else
              InertiaRails.broadcast_refresh_to(streamable, request_id: request_id)
            end
          end
        end
      end

      # Executes +block+ preventing broadcasts from this model only.
      def suppressing_inertia_broadcasts(&block)
        original, self.suppressed_inertia_broadcasts = suppressed_inertia_broadcasts, true
        yield
      ensure
        self.suppressed_inertia_broadcasts = original
      end

      def suppressed_inertia_broadcasts?
        suppressed_inertia_broadcasts
      end
    end

    private

    def resolve_broadcastable_target(target)
      target.respond_to?(:call) ? target.call(self) : send(target)
    end
  end
end
