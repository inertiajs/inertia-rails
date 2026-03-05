# frozen_string_literal: true

require_relative 'scroll_metadata'

module InertiaRails
  class ScrollProp < BaseProp
    prepend PropMergeable

    attr_reader :group

    def initialize(**options, &block)
      super(&block)

      @merge = true
      @deferred = options.delete(:defer) || false
      @group = options.delete(:group) || DeferProp::DEFAULT_GROUP
      @metadata = options.delete(:metadata)
      @wrapper = options.delete(:wrapper)

      @options = options
    end

    def deferred?
      @deferred
    end

    def call(controller, scroll_intent: nil, **)
      @value = super(controller)
      configure_merge_intent(scroll_intent)
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
