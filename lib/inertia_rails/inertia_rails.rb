# frozen_string_literal: true

require 'inertia_rails/base_prop'
require 'inertia_rails/ignore_on_first_load_prop'
require 'inertia_rails/always_prop'
require 'inertia_rails/lazy_prop'
require 'inertia_rails/optional_prop'
require 'inertia_rails/defer_prop'
require 'inertia_rails/merge_prop'
require 'inertia_rails/configuration'
require 'inertia_rails/meta_tag'

module InertiaRails
  class << self
    CONFIGURATION = Configuration.default

    def configure
      yield(CONFIGURATION)
    end

    def configuration
      CONFIGURATION
    end

    def lazy(value = nil, &block)
      LazyProp.new(value, &block)
    end

    def optional(&block)
      OptionalProp.new(&block)
    end

    def always(&block)
      AlwaysProp.new(&block)
    end

    def merge(match_on: nil, &block)
      MergeProp.new(match_on: match_on, &block)
    end

    def deep_merge(match_on: nil, &block)
      MergeProp.new(deep_merge: true, match_on: match_on, &block)
    end

    def defer(group: nil, merge: nil, deep_merge: nil, match_on: nil, &block)
      DeferProp.new(group: group, merge: merge, deep_merge: deep_merge, match_on: match_on, &block)
    end
  end
end
