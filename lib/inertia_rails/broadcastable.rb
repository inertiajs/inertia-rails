# frozen_string_literal: true

# Derived from turbo-rails (MIT licensed, Copyright Basecamp).
# https://github.com/hotwired/turbo-rails

module InertiaRails
  module Broadcastable
    extend ActiveSupport::Concern

    included do
      thread_mattr_accessor :suppressed_inertia_broadcasts, instance_accessor: false
      delegate :suppressed_inertia_broadcasts?, to: 'self.class'

      # Short names mirror turbo-rails. turbo-rails auto-includes its
      # Broadcastable into every ActiveRecord model, so in hybrid apps the
      # short names are already taken — there the canonical inertia_-prefixed
      # macros are used side by side with Turbo's:
      #
      #   broadcasts_to ->(t) { t.board }             # Turbo → ERB pages
      #   inertia_broadcasts_to ->(t) { t.board }     # ours  → Inertia pages
      unless respond_to?(:broadcasts_to)
        singleton_class.alias_method :broadcasts_to, :inertia_broadcasts_to
      end
      unless respond_to?(:broadcasts_refreshes_to)
        singleton_class.alias_method :broadcasts_refreshes_to, :inertia_broadcasts_refreshes_to
      end
    end

    class_methods do
      # Configures the model to broadcast lifecycle facts ({type, model, id})
      # on create, update, and destroy to the stream derived from +target+.
      # No payloads: clients coalesce facts into partial reloads (or filter
      # destroys locally when the prop opted in).
      #
      #   class Message < ApplicationRecord
      #     belongs_to :board
      #     inertia_broadcasts_to :board
      #   end
      #
      #   class Message < ApplicationRecord
      #     inertia_broadcasts_to ->(message) { [message.board, :messages] }
      #   end
      def inertia_broadcasts_to(target, on: Broadcast::ACTIONS, **options)
        filter_opts = options.slice(:if, :unless)

        Array(on).each do |event|
          after_commit(on: event, **filter_opts) do
            next if self.class.suppressed_inertia_broadcasts?

            streamable = resolve_broadcastable_target(target)
            InertiaRails.broadcast_change_to(
              streamable,
              record: self,
              action: event,
              request_id: InertiaRails::Current.live_request_id
            )
          end
        end
      end

      # Configures the model to broadcast a bare "reload" signal on create,
      # update, and destroy. Refreshes are debounced by default so rapid
      # same-request changes coalesce into a single broadcast. (Change signals
      # are never debounced — coalescing typed facts drops destroys.)
      #
      #   class Column < ApplicationRecord
      #     inertia_broadcasts_refreshes_to :board
      #   end
      def inertia_broadcasts_refreshes_to(target, on: Broadcast::ACTIONS, debounce: InertiaRails::Debouncer::DEFAULT_DELAY, **options)
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
