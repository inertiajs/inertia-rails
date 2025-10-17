# frozen_string_literal: true

require_relative 'scroll_metadata'

module InertiaRails
  class ScrollProp < BaseProp
    prepend PropMergeable

    def initialize(**options, &block)
      super(&block)

      @merge = true
      @metadata = options.delete(:metadata)
      @wrapper = options.delete(:wrapper)

      @options = options
    end

    def call(controller)
      @value = super
      configure_merge_intent(controller.request.headers['X-Inertia-Infinite-Scroll-Merge-Intent'])
      @value
    end

    def metadata
      ScrollMetadata.extract(@metadata, **@options)
    end

    private

    def configure_merge_intent(scroll_intent)
      scroll_intent == 'prepend' ? prepend(@wrapper || true) : append(@wrapper || true)
    end
  end
end
