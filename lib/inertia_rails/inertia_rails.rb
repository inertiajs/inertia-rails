require 'inertia_rails/base_prop'
require 'inertia_rails/ignore_on_first_load_prop'
require 'inertia_rails/always_prop'
require 'inertia_rails/lazy_prop'
require 'inertia_rails/optional_prop'
require 'inertia_rails/defer_prop'
require 'inertia_rails/merge_prop'
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

    def lazy(value = nil, &block)
      LazyProp.new(value, &block)
    end

    def optional(&block)
      OptionalProp.new(&block)
    end

    def always(&block)
      AlwaysProp.new(&block)
    end

    def merge(&block)
      MergeProp.new(&block)
    end

    def defer(group: nil, merge: nil, &block)
      DeferProp.new(group: group, merge: merge, &block)
    end
  end
end
