class InertiaRails::Lazy
  def initialize(value = nil, &block)
    @value = value
    @block = block
  end

  def call
    to_proc.call
  end

  def to_proc
    # copy to local variables so they are in scope for controller.instance_exec
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
