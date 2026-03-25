# frozen_string_literal: true

# stdlib
require 'digest/md5'
require 'json'
require 'net/http'

# modules
require_relative 'inertia_rails/version'
require_relative 'inertia_rails/configuration'
require_relative 'inertia_rails/current'
require_relative 'inertia_rails/errors'

# props
require_relative 'inertia_rails/prop_onceable'
require_relative 'inertia_rails/prop_mergeable'
require_relative 'inertia_rails/base_prop'
require_relative 'inertia_rails/ignore_on_first_load_prop'
require_relative 'inertia_rails/always_prop'
require_relative 'inertia_rails/lazy_prop'
require_relative 'inertia_rails/optional_prop'
require_relative 'inertia_rails/defer_prop'
require_relative 'inertia_rails/merge_prop'
require_relative 'inertia_rails/once_prop'
require_relative 'inertia_rails/scroll_metadata'
require_relative 'inertia_rails/scroll_prop'
require_relative 'inertia_rails/prop_evaluator'
require_relative 'inertia_rails/props_resolver'

# rendering
require_relative 'inertia_rails/meta_tag'
require_relative 'inertia_rails/meta_tag_builder'
require_relative 'inertia_rails/ssr_renderer'
require_relative 'inertia_rails/renderer'

# rails integration
require_relative 'inertia_rails/flash_extension'
require_relative 'inertia_rails/helper'
require_relative 'inertia_rails/precognition'
require_relative 'inertia_rails/controller'
require_relative 'inertia_rails/middleware'
require_relative 'inertia_rails/engine'

module InertiaRails
  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.default
    end

    def deprecator # :nodoc:
      @deprecator ||= ActiveSupport::Deprecation.new
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
