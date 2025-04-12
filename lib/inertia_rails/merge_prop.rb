# frozen_string_literal: true

module InertiaRails
  class MergeProp < BaseProp
    def initialize(deep_merge: false, &block)
      super(&block)
      @deep_merge = deep_merge
    end

    def merge?
      true
    end

    def deep_merge?
      @deep_merge
    end
  end
end
