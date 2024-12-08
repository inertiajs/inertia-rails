# frozen_string_literal: true

module InertiaRails
  class DeferProp < IgnoreOnFirstLoadProp
    DEFAULT_GROUP = 'default'

    attr_reader :group

    def initialize(group: nil, merge: nil, &block)
      super(&block)

      @group = group || DEFAULT_GROUP
      @merge = merge
      @block = block
    end

    def merge?
      @merge
    end
  end
end
