# frozen_string_literal: true

require 'inertia_rails/prop_onceable'
require 'inertia_rails/prop_mergeable'
require 'inertia_rails/base_prop'
require 'inertia_rails/ignore_on_first_load_prop'
require 'inertia_rails/always_prop'
require 'inertia_rails/lazy_prop'
require 'inertia_rails/optional_prop'
require 'inertia_rails/defer_prop'
require 'inertia_rails/merge_prop'
require 'inertia_rails/once_prop'
require 'inertia_rails/scroll_prop'
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

    def optional(...)
      OptionalProp.new(...)
    end

    def always(&block)
      AlwaysProp.new(&block)
    end

    def once(...)
      OnceProp.new(...)
    end

    def merge(...)
      MergeProp.new(...)
    end

    def deep_merge(match_on: nil, &block)
      MergeProp.new(deep_merge: true, match_on: match_on, &block)
    end

    def defer(...)
      DeferProp.new(...)
    end

    def scroll(metadata = nil, **options, &block)
      ScrollProp.new(metadata: metadata, **options, &block)
    end
  end
end
