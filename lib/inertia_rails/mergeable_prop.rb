module InertiaRails
  module MergeableProp
    def merge
      @merge = true
      self
    end

    def merge?
      @merge
    end
  end
end
