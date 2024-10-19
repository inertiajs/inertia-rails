module InertiaRails
  class BaseProp
    def initialize(value = nil, &block)
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
