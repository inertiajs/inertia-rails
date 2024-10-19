module InertiaRails
  class BaseProp
    def initialize(value = nil, &block)
      @value = value
      @block = block
    end

    def call
      to_proc.call
    end

    private

    def to_proc
      # This is called by controller.instance_exec, which changes self to the
      # controller instance. That makes the instance variables unavailable to the
      # proc via closure. Copying the instance variables to local variables before
      # the proc is returned keeps them in scope for the returned proc.
      value = @value
      return value if value.respond_to?(:call)
      return Proc.new { value } if value

      @block
    end
  end
end
