# frozen_string_literal: true

module InertiaRails
  # Provides a scoped interface for Inertia flash data within Rails' flash.
  # Uses native hash storage: flash[:inertia] = { key: value }
  # Tracks .now keys separately in @inertia_now_keys for session filtering.
  module FlashExtension
    INERTIA_KEY = 'inertia'

    def inertia
      @inertia ||= InertiaFlashScope.new(self)
    end

    # Keys set via flash.now.inertia that should not persist to session
    def inertia_now_keys
      @inertia_now_keys ||= Set.new
    end

    # Clear .now tracking when user explicitly keeps :inertia or all flash
    def keep(key = nil)
      @inertia_now_keys&.clear if key.nil? || key.to_s == INERTIA_KEY
      super
    end

    # Override to filter .now keys from nested inertia hash before session persistence
    def to_session_value
      inertia_hash = self[INERTIA_KEY]
      if inertia_hash.is_a?(Hash) && @inertia_now_keys&.any?
        @inertia_now_keys.each { |k| inertia_hash.delete(k.to_s) }
        delete(INERTIA_KEY) if inertia_hash.empty?
      end

      super
    end

    class InertiaFlashScope
      def initialize(flash_or_now)
        if flash_or_now.respond_to?(:flash)
          @flash = flash_or_now.flash
          @now = true
        else
          @flash = flash_or_now
          @now = false
        end
      end

      def []=(key, value)
        @flash[INERTIA_KEY] ||= {}
        @flash[INERTIA_KEY][key.to_s] = value
        @flash.inertia_now_keys.add(key.to_s) if @now
      end

      def [](key)
        @flash[INERTIA_KEY]&.[](key.to_s)
      end

      def to_hash
        @flash[INERTIA_KEY]&.dup || {}
      end
      alias to_h to_hash
    end
  end
end
