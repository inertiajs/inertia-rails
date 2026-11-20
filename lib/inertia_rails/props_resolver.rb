# frozen_string_literal: true

module InertiaRails
  # Resolves props and collects metadata (deferred, merge, once, scroll)
  # for the Inertia page response.
  class PropsResolver
    SKIP = Object.new.freeze
    private_constant :SKIP

    # Known by class, and so not asked whether they have `to_inertia`.
    PLAIN_CLASSES = [String, Symbol, Integer, Float, NilClass, TrueClass, FalseClass]
                    .to_h { |plain_class| [plain_class, true] }.compare_by_identity.freeze
    private_constant :PLAIN_CLASSES

    # `ActiveSupport::OrderedOptions` answers every method, `to_inertia` included, with a key lookup.
    def self.serializer?(value)
      value.respond_to?(:to_inertia) && !value.is_a?(ActiveSupport::OrderedOptions)
    end

    def initialize(props, evaluator:, visit: {}, recorder: nil)
      @props = props
      @evaluator = evaluator
      @recorder = recorder
      @partial_component = visit[:component] || false
      @partial_keys = visit[:only] || []
      @partial_except_keys = visit[:except] || []
      @reset_keys = visit[:reset] || []
      @except_once_keys = visit[:except_once] || []
      @scroll_intent = visit[:scroll_intent]
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
      @_rescued = []

      @keys = []
      @whole = false

      props = expand_dot_notation(@props)
      [resolve_hash(props), build_metadata]
    end

    private

    attr_reader :partial_keys, :partial_except_keys, :reset_keys, :except_once_keys

    def expand_dot_notation(props)
      dotted, plain = props.partition { |key, _| key.to_s.include?('.') }
      result = merge_plain_keys(plain)
      position = props.each_key.with_index.to_h { |key, index| [key.to_s, index] }

      dotted.each do |key, value|
        parts = key.to_s.split('.')
        parent_position = position[parts.first]
        # A dotted key that came before the plain key it extends leaves what that key sets itself,
        # so the later key wins either way.
        came_first = !parent_position.nil? && position[key.to_s] < parent_position
        write_dotted(result, parts.map(&:to_sym), value, keep: came_first)
      end
      result
    end

    # A key may be given twice, as a String and as a Symbol.
    def merge_plain_keys(plain)
      plain.each_with_object({}) do |(key, value), result|
        key = key.to_sym
        if value.is_a?(Hash) && result[key].is_a?(Hash)
          result[key].merge!(value)
        else
          result[key] = value
        end
      end
    end

    def write_dotted(target, parts, value, keep:)
      key, *rest = parts
      if rest.empty?
        target[key] = value unless keep && target.key?(key)
      elsif evaluated_later?(target[key])
        target[key] = write_dotted_later(target[key], parts, value, keep: keep)
      elsif (inner = hash_at(target, key, keep: keep))
        write_dotted(inner, rest, value, keep: keep)
      end
    end

    def evaluated_later?(value)
      value.is_a?(Proc) || self.class.serializer?(value)
    end

    # A closure or serializer is asked for its hash when the walk gets to it,
    # so one that a partial reload skips is never called.
    def write_dotted_later(parent, parts, value, keep:)
      key = parts.first
      write = lambda do
        evaluated = { key => self.class.serializer?(parent) ? parent.to_inertia : @evaluator.call(parent) }
        write_dotted(evaluated, parts, value, keep: keep)
        evaluated[key]
      end
      -> { write.call }
    end

    # Returns the hash under `key` as a copy. A value that is not a hash is replaced by an empty one,
    # unless `keep` is given: then it stays and `nil` is returned.
    def hash_at(current, key, keep:)
      value = current[key]
      return if keep && current.key?(key) && !value.is_a?(Hash)

      current[key] = value.is_a?(Hash) ? value.dup : {}
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
      metadata[:rescuedProps] = @_rescued unless @_rescued.empty?

      metadata
    end

    # A hash leaves out what is not sent.
    # Speed: where nothing is skipped, a plain value is sent as it is, without a step to its key.
    def resolve_hash(hash)
      plain_leaves = nothing_to_check_on_plain_leaves?
      props = {}
      hash.each do |key, value|
        next props[key] = value if plain_leaves && plain_leaf?(value)

        prop = at(key) { resolve_prop(value) }
        props[key] = prop unless prop.equal?(SKIP)
      end
      props
    end

    def resolve_prop(value)
      return SKIP if skipped? && !value.is_a?(AlwaysProp)

      record(value) unless value.is_a?(BaseProp)
      resolve_value(value)
    end

    # An array keeps every place, since partial reloads refer to elements by position.
    def resolve_array(array)
      return array unless needs_transform?(array) || partial_request_reaches_below?

      array.each_with_index.map { |item, index| at(index) { resolve_element(item) } }
    end

    # A hash stays a hash, with what is left of it. Anything else that is not sent leaves `nil`.
    def resolve_element(item)
      return resolve_hash(item) if item.is_a?(Hash)
      return if skipped?

      element = resolve_value(item)
      element unless element.equal?(SKIP)
    end

    # Any value, wherever it sits: a serializer, closure or prop type is asked for what it holds,
    # until plain data is left to walk.
    def resolve_value(value)
      return value if PLAIN_CLASSES[value.class]
      return resolve_returned(value, to_inertia(value)) if self.class.serializer?(value)

      case value
      when BaseProp then resolve_prop_type(value)
      when Proc then resolve_returned(value, @evaluator.call(value))
      when Hash then skip_if_emptied(value, resolve_hash(value))
      when Array then resolve_array(value)
      else value
      end
    end

    # What returns itself has nothing more to give.
    def resolve_returned(from, returned)
      returned.equal?(from) ? returned : resolve_value(returned)
    end

    def resolve_prop_type(prop)
      prop = prop.with_merge_intent(@scroll_intent) if prop.is_a?(ScrollProp)
      collect_metadata(prop, path)
      return SKIP if waits_for_partial_reload?(prop) || excluded_by_once_cache?(prop, path)

      record(prop)
      prop.try(:rescue?) ? evaluate_rescued(prop) : evaluate(prop)
    end

    # An always prop ignores `only` and `except`, and so does everything it returns.
    def evaluate(prop)
      returned = @evaluator.call(prop)
      prop.is_a?(AlwaysProp) ? whole { resolve_value(returned) } : resolve_value(returned)
    end

    # `as_json` runs here so that an error raised while serializing the prop is rescued too.
    def evaluate_rescued(prop)
      resolved = evaluate(prop)
      return SKIP if resolved.equal?(SKIP)

      resolved.as_json
    rescue StandardError => e
      report_rescued_error(e)
      @_rescued << path
      SKIP
    end

    # A hash the walk emptied is not sent. One given empty is sent as it is.
    def skip_if_emptied(hash, props)
      props.empty? && !hash.empty? ? SKIP : props
    end

    # Steps down to `key` for the length of the block.
    def at(key)
      outer = @path
      @keys << key
      @path = outer && "#{outer}.#{key}"
      yield
    ensure
      @keys.pop
      @path = outer
    end

    # The name the client knows the prop by. Built only when asked for.
    # `join` alone would flatten a key that is an Array.
    def path
      @path ||= @keys.reduce { |path, key| "#{path}.#{key}" }.to_s
    end

    def whole
      outer = @whole
      @whole = true
      yield
    ensure
      @whole = outer
    end

    def skipped?
      !@whole && filtering_partial_request? && excluded_by_partial_request?(path)
    end

    def to_inertia(value)
      return value unless self.class.serializer?(value)

      @recorder&.serializer_found(value, path)
      value.to_inertia
    end

    def record(value)
      @recorder&.prop_resolved(path, value, reset: reset_keys.include?(path))
    end

    # DevTools records every prop, plain values too.
    def nothing_to_check_on_plain_leaves?
      @recorder.nil? && (@whole || !filtering_partial_request?)
    end

    def plain_leaf?(value)
      return true if PLAIN_CLASSES[value.class]

      case value
      when BaseProp, Proc, Hash, Array then false
      else !self.class.serializer?(value)
      end
    end

    # Explicit loops reduce per-element overhead on large plain-data arrays.
    def needs_transform?(value)
      return false if PLAIN_CLASSES[value.class]

      case value
      when BaseProp, Proc then true
      when Hash
        value.each_value { |v| return true if needs_transform?(v) }
        false
      when Array
        value.each { |v| return true if needs_transform?(v) }
        false
      else self.class.serializer?(value)
      end
    end

    def report_rescued_error(error)
      # `Rails.error` (the Error Reporter) was introduced in Rails 7.0. Fall back
      # to the logger on older versions so rescued errors are never silently lost.
      if Rails.respond_to?(:error)
        Rails.error.report(error, handled: true)
      else
        Rails.logger&.error("[inertia-rails] Rescued deferred prop error: #{error.class}: #{error.message}")
      end
    end

    def collect_metadata(prop, path)
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

    # Optional and deferred props wait for a partial reload.
    def waits_for_partial_reload?(prop)
      (prop.is_a?(IgnoreOnFirstLoadProp) || prop.try(:deferred?)) && !rendering_partial_component?
    end

    def excluded_by_once_cache?(prop, path)
      return false unless prop.try(:once?)
      return false if prop.try(:fresh?)
      return false if rendering_partial_component?

      once_key = (prop.once_key || path).to_s
      except_once_keys.include?(once_key)
    end

    def filtering_partial_request?
      rendering_partial_component? && (partial_keys.present? || partial_except_keys.present?)
    end

    # Arrays of plain values are skipped as a shortcut, unless a partial reload names an
    # element inside one.
    def partial_request_reaches_below?
      return false unless filtering_partial_request?

      path_prefix = "#{path}."
      partial_keys.any? { |key| key.start_with?(path_prefix) } ||
        partial_except_keys.any? { |key| key.start_with?(path_prefix) }
    end

    def excluded_by_partial_request?(path)
      return false unless filtering_partial_request?

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
