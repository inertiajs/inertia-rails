# frozen_string_literal: true

module InertiaRails
  class MergeProp < BaseProp
    def initialize(*)
      super
      @merge = true
    end

    def merge?
      @merge
    end
  end
end
