module InertiaRails
  class DeferProp < IgnoreOnFirstLoadProp
    DEFAULT_GROUP = "default".freeze

    attr_reader :group

    def initialize(group: nil, &block)
      @group = group || DEFAULT_GROUP
      @block = block
    end
  end
end
