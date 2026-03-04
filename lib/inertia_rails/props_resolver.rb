# frozen_string_literal: true

require_relative 'prop_evaluator'

module InertiaRails
  # Resolves props and collects metadata (deferred, merge, once, scroll)
  # for the Inertia page response.
  class PropsResolver
    def initialize(props, evaluator:, visit: {})
      @props = props
      @evaluator = evaluator
      @partial_component = visit[:component] || false
      @partial_keys = visit[:only] || []
      @partial_except_keys = visit[:except] || []
      @reset_keys = visit[:reset] || []
      @except_once_keys = visit[:except_once] || []
    end

    # Returns [resolved_props, metadata]
    # where metadata is a hash with keys like :deferredProps, :mergeProps, etc.
    def resolve
      resolved = computed_props
      metadata = build_metadata
      [resolved, metadata]
    end

    private

    attr_reader :partial_keys, :partial_except_keys, :reset_keys, :except_once_keys

    def computed_props
      @props.tap do |merged_props|
        # Always keep errors in the props
        if merged_props.key?(:errors) && !merged_props[:errors].is_a?(BaseProp)
          errors = merged_props[:errors]
          merged_props[:errors] = InertiaRails.always { errors }
        end
      end

      deep_transform_props(@props)
    end

    def build_metadata
      metadata = {}

      deferred = deferred_props_keys
      metadata[:deferredProps] = deferred if deferred.present?
      metadata[:scrollProps] = scroll_props if scroll_props.present?
      metadata.merge!(resolve_merge_props)

      once = resolve_once_props
      metadata[:onceProps] = once if once.present?

      metadata
    end

    def deep_transform_props(props, parent_path = [])
      props.each_with_object({}) do |(key, prop), transformed_props|
        current_path = parent_path + [key]

        if prop.is_a?(Hash) && prop.any?
          nested = deep_transform_props(prop, current_path)
          transformed_props[key] = nested unless nested.empty?
        elsif keep_prop?(prop, current_path)
          transformed_props[key] = @evaluator.call(prop)
        end
      end
    end

    def deferred_props_keys
      return if rendering_partial_component?

      @props.each_with_object({}) do |(key, prop), result|
        (result[prop.group] ||= []) << key if prop.try(:deferred?)
      end
    end

    def resolve_merge_props
      deep_merge_props, merge_props = all_merge_props.partition do |_key, prop|
        prop.deep_merge?
      end

      {
        mergeProps: append_merge_props(merge_props),
        prependProps: prepend_merge_props(merge_props),
        deepMergeProps: deep_merge_props.map!(&:first),
        matchPropsOn: resolve_match_on_props,
      }.delete_if { |_, v| v.blank? }
    end

    def resolve_once_props
      @props.each_with_object({}) do |(key, prop), result|
        next unless prop.try(:once?)
        next if excluded_by_partial_request?([key.to_s])

        once_key = (prop.once_key || key).to_s

        result[once_key] = { prop: key.to_s, expiresAt: prop.expires_at }.compact
      end
    end

    def resolve_match_on_props
      all_merge_props.filter_map do |key, prop|
        prop.match_on.map! { |ms| "#{key}.#{ms}" } if prop.match_on.present?
      end.flatten
    end

    def requested_merge_props
      @requested_merge_props ||= @props.select do |key, prop|
        next unless prop.try(:merge?)
        next if rendering_partial_component? && (
          (partial_keys.present? && partial_keys.exclude?(key.name)) ||
            (partial_except_keys.present? && partial_except_keys.include?(key.name))
        )

        true
      end
    end

    def append_merge_props(props)
      return props if props.empty?

      root_append_props, nested_append_props = props.partition { |_key, prop| prop.appends_at_root? }

      result = Set.new(root_append_props.map!(&:first))

      nested_append_props.each do |key, prop|
        prop.appends_at_paths.each do |path|
          result.add("#{key}.#{path}")
        end
      end

      result.to_a
    end

    def prepend_merge_props(props)
      return props if props.empty?

      root_prepend_props, nested_prepend_props = props.partition { |_key, prop| prop.prepends_at_root? }

      result = Set.new(root_prepend_props.map!(&:first))

      nested_prepend_props.each do |key, prop|
        prop.prepends_at_paths.each do |path|
          result.add("#{key}.#{path}")
        end
      end

      result.to_a
    end

    def scroll_props
      return @scroll_props if defined?(@scroll_props)

      @scroll_props = {}
      requested_merge_props.each do |key, prop|
        next unless prop.is_a?(ScrollProp)
        next if prop.deferred? && !rendering_partial_component?

        @scroll_props[key] = prop.metadata.merge!(reset: reset_keys.include?(key.name))
      end
      @scroll_props
    end

    def all_merge_props
      @all_merge_props ||= requested_merge_props.reject { |key,| reset_keys.include?(key.name) }
    end

    def rendering_partial_component?
      @partial_component
    end

    def keep_prop?(prop, path)
      return true if prop.is_a?(AlwaysProp)
      return false if excluded_by_once_cache?(prop, path)
      return false if excluded_by_partial_request?(path)

      # Precedence: Evaluate IgnoreOnFirstLoadProp only after partial keys have been checked
      return false if (prop.is_a?(IgnoreOnFirstLoadProp) || prop.try(:deferred?)) && !rendering_partial_component?

      true
    end

    def excluded_by_once_cache?(prop, path)
      return false unless prop.try(:once?)
      return false if prop.try(:fresh?)
      return false if explicitly_requested?(path)

      once_key = (prop.once_key || path.join('.')).to_s
      except_once_keys.include?(once_key)
    end

    def explicitly_requested?(path)
      return false unless rendering_partial_component? && partial_keys.present?

      path_with_prefixes = path_prefixes(path)
      (path_with_prefixes & partial_keys).any?
    end

    def excluded_by_partial_request?(path)
      return false unless rendering_partial_component? && (partial_keys.present? || partial_except_keys.present?)

      path_with_prefixes = path_prefixes(path)
      excluded_by_only_partial_keys?(path_with_prefixes) || excluded_by_except_partial_keys?(path_with_prefixes)
    end

    def path_prefixes(parts)
      (0...parts.length).map do |i|
        parts[0..i].join('.')
      end
    end

    def excluded_by_only_partial_keys?(path_with_prefixes)
      partial_keys.present? && (path_with_prefixes & partial_keys).empty?
    end

    def excluded_by_except_partial_keys?(path_with_prefixes)
      partial_except_keys.present? && (path_with_prefixes & partial_except_keys).any?
    end
  end
end
