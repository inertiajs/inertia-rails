# Needed for `thread_mattr_accessor`
require 'active_support/core_ext/module/attribute_accessors_per_thread'
require 'inertia_rails/mergeable_prop'
require 'inertia_rails/base_prop'
require 'inertia_rails/ignore_first_load_prop'
require 'inertia_rails/optional_prop'
require 'inertia_rails/always_prop'
require 'inertia_rails/merge_prop'
require 'inertia_rails/defer_prop'
require 'inertia_rails/configuration'

module InertiaRails
  class << self
    CONFIGURATION = Configuration.default

    def configure
      yield(CONFIGURATION)
    end

    def configuration
      CONFIGURATION
    end

    def optional(value = nil, &block)
      OptionalProp.new(value, &block)
    end
    alias_method :lazy, :optional

    def defer(value = nil, group = nil, &block)
      DeferProp.new(value, group, &block)
    end

    def merge(value = nil, &block)
      MergeProp.new(value, &block)
    end

    def always(value = nil, &block)
      AlwaysProp.new(value, &block)
    end
  end
end
