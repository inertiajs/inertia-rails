# frozen_string_literal: true

module InertiaRails
  # Base class for all props.
  class BaseProp
    def initialize(value = nil, &block)
      raise ArgumentError, 'You must provide either a value or a block, not both' if value && block

      @value = value
      @block = block
    end

    def call(controller)
      value.respond_to?(:call) ? controller.instance_exec(&value) : value
    end

    def value
      @value.nil? ? @block : @value
    end
  end
end
