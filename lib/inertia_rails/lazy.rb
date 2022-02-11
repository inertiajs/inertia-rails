module InertiaRails
  class Lazy
    def initialize(value = nil, &block)
      @value = value
      @block = block
    end

    def call
      to_proc.call
    end

    def to_proc
      # This is called by controller.instance_exec, which changes self to the
      # controller instance. That makes the instance variables unavailable to the
      # proc via closure. Copying the instance variables to local variables before
      # the proc is returned keeps them in scope for the returned proc.
      value = @value
      block = @block
      if value.respond_to?(:call)
        value
      elsif value
        Proc.new { value }
      else
        block
      end
    end
  end
end
