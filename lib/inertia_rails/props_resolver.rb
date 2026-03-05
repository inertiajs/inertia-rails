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
      @_deferred = {}
      @_merge = []
      @_prepend = []
      @_deep_merge = []
      @_match_on = []
      @_once = {}
      @_scroll = {}

      props = expand_dot_notation(@props)
      resolved = deep_transform_props(props)
      [resolved, build_metadata]
    end

    private

    attr_reader :partial_keys, :partial_except_keys, :reset_keys, :except_once_keys

    def expand_dot_notation(props)
      result = {}
      props.each do |key, value|
        if key.is_a?(String) && key.include?('.')
          parts = key.split('.')
          current = result
          parts[0..-2].each { |part| current = resolve_value(current, part.to_sym) }
          current[parts.last.to_sym] = value
        else
          key = key.to_sym
          if value.is_a?(Hash) && result[key].is_a?(Hash)
            result[key].merge!(value)
          else
            result[key] = value
          end
        end
      end
      result
    end

    def resolve_value(current, key)
      value = current[key]
      value = value.to_inertia if value.respond_to?(:to_inertia)
      value = @evaluator.call(value) if value.is_a?(Proc)
      current[key] = value || {}
    end

    def build_metadata
      metadata = {}

      metadata[:deferredProps] = @_deferred unless @_deferred.empty?
      metadata[:scrollProps] = @_scroll unless @_scroll.empty?
      metadata[:mergeProps] = @_merge unless @_merge.empty?
      metadata[:prependProps] = @_prepend unless @_prepend.empty?
      metadata[:deepMergeProps] = @_deep_merge unless @_deep_merge.empty?
      metadata[:matchPropsOn] = @_match_on unless @_match_on.empty?
      metadata[:onceProps] = @_once unless @_once.empty?

      metadata
    end

    def deep_transform_props(props, prefix = '', parent_was_resolved: false)
      props.each_with_object({}) do |(key, prop), transformed_props|
        path = prefix.empty? ? key.to_s : "#{prefix}.#{key}"

        prop = prop.to_inertia if prop.respond_to?(:to_inertia)

        if prop.is_a?(Hash) && prop.any?
          nested = deep_transform_props(prop, path, parent_was_resolved: parent_was_resolved)
          transformed_props[key] = nested unless nested.empty?
          next
        end

        if prop.is_a?(Array)
          unless needs_transform?(prop)
            transformed_props[key] = prop
            next
          end
          transformed_props[key] = prop.each_with_index.filter_map do |item, i|
            if item.is_a?(Hash)
              nested = deep_transform_props(item, "#{path}.#{i}", parent_was_resolved: parent_was_resolved)
              nested unless nested.empty?
            else
              @evaluator.call(item)
            end
          end
          next
        end

        collect_metadata(prop, path)
        next unless keep_prop?(prop, path, parent_was_resolved: parent_was_resolved)

        value = @evaluator.call(prop)

        # A closure may return a prop type — unwrap one level
        if value.is_a?(BaseProp) && !prop.is_a?(BaseProp)
          collect_metadata(value, path)
          next unless keep_prop?(value, path, parent_was_resolved: parent_was_resolved)

          value = @evaluator.call(value)
        end

        # A closure may return a Hash or Array containing prop types — recurse into it
        if prop.is_a?(Proc)
          if value.is_a?(Hash) && value.any?
            nested = deep_transform_props(value, path, parent_was_resolved: true)
            transformed_props[key] = nested unless nested.empty?
            next
          elsif value.is_a?(Array)
            # Optimization: do not map over the array if no transform needed
            unless needs_transform?(value)
              transformed_props[key] = value
              next
            end
            transformed_props[key] = value.each_with_index.filter_map do |item, i|
              if item.is_a?(Hash)
                nested = deep_transform_props(item, "#{path}.#{i}", parent_was_resolved: true)
                nested unless nested.empty?
              else
                @evaluator.call(item)
              end
            end
            next
          end
        end

        transformed_props[key] = value
      end
    end

    def needs_transform?(value)
      case value
      when BaseProp, Proc then true
      when Hash then value.any? { |_, v| needs_transform?(v) }
      when Array then value.any? { |v| needs_transform?(v) }
      else value.respond_to?(:to_inertia)
      end
    end

    def collect_metadata(prop, path)
      return unless prop.is_a?(BaseProp)

      collect_deferred_metadata(prop, path)
      collect_merge_metadata(prop, path)
      collect_once_metadata(prop, path)
    end

    def collect_deferred_metadata(prop, path)
      return unless prop.try(:deferred?) && !rendering_partial_component?
      return if excluded_by_once_cache?(prop, path)

      (@_deferred[prop.group] ||= []) << path
    end

    def collect_merge_metadata(prop, path)
      return unless prop.try(:merge?)
      return if rendering_partial_component? && excluded_by_partial_request?(path)

      resetting = reset_keys.include?(path)

      if prop.is_a?(ScrollProp) && (rendering_partial_component? || !prop.deferred?)
        @_scroll[path] = prop.metadata.merge(reset: resetting)
      end

      return if resetting

      if prop.deep_merge?
        @_deep_merge << path
      elsif prop.appends_at_root?
        @_merge << path
      elsif prop.prepends_at_root?
        @_prepend << path
      else
        prop.appends_at_paths.each { |p| @_merge << "#{path}.#{p}" }
        prop.prepends_at_paths.each { |p| @_prepend << "#{path}.#{p}" }
      end

      prop.match_on&.each { |ms| @_match_on << "#{path}.#{ms}" }
    end

    def collect_once_metadata(prop, path)
      return unless prop.try(:once?)
      return if excluded_by_partial_request?(path)

      once_key = (prop.once_key || path).to_s
      @_once[once_key] = { prop: path, expiresAt: prop.expires_at }.compact
    end

    def rendering_partial_component?
      @partial_component
    end

    def keep_prop?(prop, path, parent_was_resolved: false)
      return true if prop.is_a?(AlwaysProp)
      return false if excluded_by_once_cache?(prop, path)
      return false if !parent_was_resolved && excluded_by_partial_request?(path)

      # Precedence: Evaluate IgnoreOnFirstLoadProp only after partial keys have been checked
      return false if (prop.is_a?(IgnoreOnFirstLoadProp) || prop.try(:deferred?)) && !rendering_partial_component?

      true
    end

    def excluded_by_once_cache?(prop, path)
      return false unless prop.try(:once?)
      return false if prop.try(:fresh?)
      return false if explicitly_requested?(path)

      once_key = (prop.once_key || path).to_s
      except_once_keys.include?(once_key)
    end

    def explicitly_requested?(path)
      return false unless rendering_partial_component? && partial_keys.present?

      path_prefix = "#{path}."
      partial_keys.any? { |key| key == path || key.start_with?(path_prefix) || path.start_with?("#{key}.") }
    end

    def excluded_by_partial_request?(path)
      return false unless rendering_partial_component? && (partial_keys.present? || partial_except_keys.present?)

      excluded_by_only_partial_keys?(path) || excluded_by_except_partial_keys?(path)
    end

    def excluded_by_only_partial_keys?(path)
      return false unless partial_keys.present?

      path_prefix = "#{path}."
      partial_keys.none? { |key| key == path || path.start_with?("#{key}.") || key.start_with?(path_prefix) }
    end

    def excluded_by_except_partial_keys?(path)
      partial_except_keys.present? && partial_except_keys.any? { |key| key == path || path.start_with?("#{key}.") }
    end
  end
end
