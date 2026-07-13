# frozen_string_literal: true

module InertiaRails
  class OnceProp < BaseProp
    prepend PropOnceable

    def initialize(**, &block)
      @once = true
      super(&block)
    end
  end
end
