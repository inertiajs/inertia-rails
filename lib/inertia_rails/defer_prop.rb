# frozen_string_literal: true

module InertiaRails
  class DeferProp < IgnoreOnFirstLoadProp
    DEFAULT_GROUP = 'default'

    attr_reader :group, :match_on

    def initialize(group: nil, merge: nil, deep_merge: nil, match_on: nil, &block)
      raise ArgumentError, 'Cannot set both `deep_merge` and `merge` to true' if deep_merge && merge

      super(&block)

      @group = group || DEFAULT_GROUP
      @merge = merge || deep_merge
      @deep_merge = deep_merge
      @match_on = match_on.nil? ? nil : Array(match_on)
    end

    def merge?
      @merge
    end

    def deep_merge?
      @deep_merge
    end
  end
end
