module InertiaRails
  class DeferProp < IgnoreFirstLoadProp
    DEFAULT_GROUP = "default".freeze

    def initialize(value = nil, group = nil, &block)
      @group = group || DEFAULT_GROUP
      @value = value
      @block = block
    end

    def group
      @group
    end
  end
end