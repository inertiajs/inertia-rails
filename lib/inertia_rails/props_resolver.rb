# frozen_string_literal: true

module InertiaRails
  # Resolves props and collects metadata (deferred, merge, once, scroll, live)
  # for the Inertia page response.
  class PropsResolver
    SKIP = Object.new.freeze
    private_constant :SKIP

    # Known by class, and so not asked whether they have `to_inertia`.
    PLAIN_CLASSES = [String, Symbol, Integer, Float, NilClass, TrueClass, FalseClass]
                    .to_h { |plain_class| [plain_class, true] }.compare_by_identity.freeze
    private_constant :PLAIN_CLASSES

    def self.serializer?(value)
      value.respond_to?(:to_inertia)
    end

    def initialize(props, evaluator:, visit: {}, recorder: nil)
      @props = props
      @evaluator = evaluator
      @recorder = recorder
      @partial_component = visit[:component] || false
      @filter = PartialFilter.build(visit[:only] || [], visit[:except] || []) if @partial_component
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
      @_live = {}
      @_rescued = []

      @keys = []
      @whole = false

      props = DottedKeys.new(@props).expand
      [resolve_hash(props), build_metadata]
    end

    private

    attr_reader :reset_keys, :except_once_keys

    def build_metadata
      metadata = {}

      metadata[:deferredProps] = @_deferred unless @_deferred.empty?
      metadata[:scrollProps] = @_scroll unless @_scroll.empty?
      metadata[:mergeProps] = @_merge unless @_merge.empty?
      metadata[:prependProps] = @_prepend unless @_prepend.empty?
      metadata[:deepMergeProps] = @_deep_merge unless @_deep_merge.empty?
      metadata[:matchPropsOn] = @_match_on unless @_match_on.empty?
      metadata[:onceProps] = @_once unless @_once.empty?
      metadata[:liveProps] = @_live unless @_live.empty?
      metadata[:rescuedProps] = @_rescued unless @_rescued.empty?

      metadata
    end

    # A hash leaves out what is not sent.
    # Speed: where nothing is skipped, a plain value is sent as it is, without a step to its key.
    def resolve_hash(hash)
      selection = hash_selection
      return whole { resolve_entries(hash, selection) } if selection == :all && !@whole

      resolve_entries(hash, selection)
    end

    def resolve_entries(hash, selection)
      plain_leaves = @recorder.nil? && selection == :all
      props = {}
      hash.each do |key, value|
        # An excluded hash still occupies its array slot. Only an always prop can add a key to it.
        next if selection == :none && !value.is_a?(AlwaysProp)

        kind = value_kind(value) if plain_leaves
        next props[key] = value if kind == :plain

        prop = at(key) { resolve_prop(value, kind) }
        props[key] = prop unless prop.equal?(SKIP)
      end
      props
    end

    def resolve_prop(value, kind)
      return SKIP if skipped? && !value.is_a?(AlwaysProp)

      record(value) unless value.is_a?(BaseProp)
      resolve_value(value, kind || value_kind(value))
    end

    # An array keeps every place, since partial reloads refer to elements by position.
    def resolve_array(array)
      return array unless @filter&.names_children?(path) || needs_transform?(array)

      array.each_with_index.map { |item, index| at(index) { resolve_element(item) } }
    end

    # A hash stays a hash, with what is left of it. Anything else that is not sent leaves `nil`.
    def resolve_element(item)
      kind = value_kind(item)
      return resolve_hash(item) if kind == :hash
      return if skipped?

      element = resolve_value(item, kind)
      element unless element.equal?(SKIP)
    end

    # Any value, wherever it sits: a serializer, closure or prop type is asked for what it holds,
    # until plain data is left to walk.
    def resolve_value(value, kind = value_kind(value))
      case kind
      when :serializer then resolve_returned(value, to_inertia(value))
      when :prop then resolve_prop_type(value)
      when :closure then resolve_returned(value, @evaluator.call(value))
      when :hash then skip_if_emptied(value, resolve_hash(value))
      when :array then resolve_array(value)
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
      # Nothing was sent, so the client keeps the listeners it has.
      @_live.delete(path)
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
      !@whole && excluded_by_partial_request?
    end

    def to_inertia(value)
      @recorder&.serializer_found(value, path)
      value.to_inertia
    end

    def record(value)
      @recorder&.prop_resolved(path, value, reset: reset_keys.include?(path))
    end

    def hash_selection
      return :all if @whole || @filter.nil?
      return :partial if @keys.empty?
      return :none unless @filter.selected?(path)

      @filter.names_children?(path) ? :partial : :all
    end

    # A collection can define its own projection. The array fast path and the walk
    # must agree that such a collection is a serializer.
    def value_kind(value)
      return :plain if PLAIN_CLASSES[value.class]
      return :serializer if self.class.serializer?(value)

      case value
      when Hash then :hash
      when Array then :array
      when BaseProp then :prop
      when Proc then :closure
      else :plain
      end
    end

    # The caller passes an array. Skip scalar children inline so large plain-data
    # arrays pay for classification only when the walk reaches another object.
    def needs_transform?(value)
      return true if value.respond_to?(:to_inertia)

      case value
      when Hash
        value.each_value { |v| return true if !PLAIN_CLASSES[v.class] && needs_transform?(v) }
      when Array
        value.each { |v| return true if !PLAIN_CLASSES[v.class] && needs_transform?(v) }
      else
        return value.is_a?(BaseProp) || value.is_a?(Proc)
      end
      false
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
      collect_live_metadata(prop, path)
    end

    def collect_deferred_metadata(prop, path)
      return unless prop.try(:deferred?) && !rendering_partial_component?
      return if excluded_by_once_cache?(prop, path)

      (@_deferred[prop.group.to_s] ||= []) << path
    end

    def collect_merge_metadata(prop, path)
      return unless prop.try(:merge?)
      return if excluded_by_partial_request?

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

    # Lists every live prop the walk reaches, sent or not, so a page subscribes to its deferred props too.
    # The client keeps its subscriptions for the props a partial reload skips.
    def collect_live_metadata(prop, path)
      @_live[path] = prop.live_metadata if prop.try(:live?)
    end

    def collect_once_metadata(prop, path)
      return unless prop.try(:once?)
      return if excluded_by_partial_request?

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

    def excluded_by_partial_request?
      @filter && !@filter.selected?(path)
    end
  end
end
