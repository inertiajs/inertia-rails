# frozen_string_literal: true

module InertiaRails
  module PropCacheable
    def initialize(**props, &block)
      cache_arg = props.delete(:cache)

      if cache_arg.is_a?(Hash)
        raise ArgumentError, 'cache: hash requires a :key' unless cache_arg.key?(:key)

        @cache_key = derive_cache_key(cache_arg.delete(:key))
        @cache_options = cache_arg.freeze
      elsif cache_arg
        @cache_key = derive_cache_key(cache_arg)
        @cache_options = nil
      end

      super
    end

    def cached?
      !@cache_key.nil?
    end

    def call(controller, **context)
      return super unless cached?

      json = InertiaRails.cache_store.fetch(@cache_key, **(@cache_options || {})) { super.to_json }
      RawJson.new(json)
    end

    private

    def derive_cache_key(raw_key)
      expanded = ActiveSupport::Cache.expand_cache_key(raw_key)
      "inertia_rails/#{expanded}"
    end
  end
end
