# frozen_string_literal: true

module InertiaRails
  class CachedProp < BaseProp
    include PropCacheable

    def initialize(cache_arg = nil, **options, &block)
      cache_options = options.extract!(:key, :expires_in, :race_condition_ttl).compact
      cache = cache_arg || cache_options.presence
      cache = cache_options.merge(key: cache) if cache_arg && cache_options.any?
      raise ArgumentError, 'cache key is required' if cache.blank?

      super(**options, cache: cache, &block)
    end
  end
end
