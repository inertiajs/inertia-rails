# frozen_string_literal: true

module InertiaRails
  module DevTools
    class Store
      def initialize
        @entries = {}
        @mutex = Mutex.new
      end

      def record(entry)
        @mutex.synchronize do
          prune_expired!
          @entries[entry.dig('__meta', 'id')] = entry
          @entries.shift while @entries.length > max_entries
        end
      end

      def fetch(id)
        @mutex.synchronize do
          prune_expired!
          @entries[id]
        end
      end

      def all
        @mutex.synchronize do
          prune_expired!
          @entries.values.dup
        end
      end

      def clear
        @mutex.synchronize { @entries.clear }
      end

      private

      def max_entries
        [Integer(InertiaRails.configuration.devtools_max_entries), 1].max
      rescue ArgumentError, TypeError
        500
      end

      def entry_ttl
        Float(InertiaRails.configuration.devtools_entry_ttl)
      rescue ArgumentError, TypeError
        3600.0
      end

      def prune_expired!
        ttl = entry_ttl
        return if ttl <= 0

        cutoff = Time.now.to_f - ttl
        @entries.delete_if { |_id, entry| entry.dig('__meta', 'utime').to_f < cutoff }
      end
    end
  end
end
