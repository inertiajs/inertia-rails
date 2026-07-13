# frozen_string_literal: true

module InertiaRails
  class CachedProp < BaseProp
    include PropCacheable

    def initialize(key, **options, &block)
      super(cache: options.merge!(key: key), &block)
    end
  end
end
