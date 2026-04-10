# frozen_string_literal: true

module InertiaRails
  class DeferProp < IgnoreOnFirstLoadProp
    prepend PropOnceable
    prepend PropMergeable
    prepend PropCacheable

    DEFAULT_GROUP = 'default'

    attr_reader :group

    def initialize(**props, &block)
      super(&block)

      @group = props[:group] || DEFAULT_GROUP
    end

    def deferred?
      true
    end
  end
end
