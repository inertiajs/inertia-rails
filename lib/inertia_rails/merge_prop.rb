# frozen_string_literal: true

module InertiaRails
  class MergeProp < BaseProp
    attr_reader :match_on

    def initialize(deep_merge: false, match_on: nil, &block)
      super(&block)
      @deep_merge = deep_merge
      @match_on = match_on.nil? ? nil : Array(match_on)
    end

    def merge?
      true
    end

    def deep_merge?
      @deep_merge
    end
  end
end
