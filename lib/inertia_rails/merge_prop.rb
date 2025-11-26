# frozen_string_literal: true

module InertiaRails
  class MergeProp < BaseProp
    prepend PropMergeable

    def initialize(**_props, &block)
      super(&block)
      @merge = true
    end
  end
end
