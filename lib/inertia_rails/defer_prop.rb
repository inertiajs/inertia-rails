module InertiaRails
  class DeferProp < IgnoreFirstLoadProp
    include MergeableProp

    DEFAULT_GROUP = "default".freeze

    attr_reader :group

    def initialize(value = nil, group = nil, &block)
      super(value, &block)

      @group = group || DEFAULT_GROUP
    end
  end
end