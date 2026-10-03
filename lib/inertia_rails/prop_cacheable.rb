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

      json = InertiaRails.cache_store.fetch(@cache_key, **(@cache_options || {})) do
        resolve_for_cache(super, controller, context).to_json
      end
      RawJson.new(json)
    end

    private

    # The cached JSON is replayed to every visit, so everything inside is evaluated now. A serializer's
    # `as_json` would cache its instance variables, and a closure or prop type would cache as junk.
    def resolve_for_cache(value, controller, context)
      return resolve_for_cache(value.to_inertia, controller, context) if PropsResolver.serializer?(value)

      case value
      when Proc then resolve_for_cache(controller.instance_exec(&value), controller, context)
      when BaseProp then resolve_for_cache(value.call(controller, **context), controller, context)
      when Hash then value.dup.transform_values! { |inner| resolve_for_cache(inner, controller, context) }
      when Array then value.dup.map! { |inner| resolve_for_cache(inner, controller, context) }
      else value
      end
    end

    def derive_cache_key(raw_key)
      expanded = ActiveSupport::Cache.expand_cache_key(raw_key)
      # `@2` retires entries cached before serializers were resolved, which may hold their instance variables.
      "inertia_rails/@2/#{expanded}"
    end
  end
end
