# frozen_string_literal: true

module InertiaRails
  # Base class for all props.
  class BaseProp
    def initialize(&block)
      @block = block
    end

    def call(controller)
      controller.instance_exec(&@block)
    end
  end
end
