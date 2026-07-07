# frozen_string_literal: true

module InertiaRails
  class LiveProp < BaseProp
    prepend PropOnceable
    prepend PropMergeable

    attr_reader :streamable

    def initialize(streamable: nil, **options, &block)
      @streamable = streamable
      super(**options, &block)
    end

    def live?
      true
    end

    def deferred?
      false
    end
  end
end
