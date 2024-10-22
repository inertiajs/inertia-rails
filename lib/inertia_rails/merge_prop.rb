module InertiaRails
  class MergeProp < BaseProp
    include MergeableProp

    def initialize(*)
      super
      @merge = true
    end
  end
end
