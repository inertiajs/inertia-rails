# frozen_string_literal: true

module InertiaRails
  class LiveProp < BaseProp
    prepend PropOnceable
    prepend PropMergeable

    attr_reader :streamable

    # +on_destroy+ policy for destroy signals on this prop:
    #   :reload (default) — refetch through the controller; correct for
    #     windowed/ordered/nested/multi-model props.
    #   a model class or name (e.g. Task or "Task") — the opt-in assertion
    #     that this prop is a flat, id-keyed, unwindowed array of exactly
    #     that model: matching destroys are filtered client-side instantly.
    # Anything else raises: a typo'd policy would otherwise match no signal
    # and silently degrade every destroy to a reload.
    #
    # merge:/match_on:/once: compose via the prop mixins as with any prop —
    # live(streamable, merge: true, match_on: 'id') makes reload responses
    # upsert instead of replace.
    def initialize(streamable:, on_destroy: :reload, **options, &block)
      @streamable = streamable
      @on_destroy = validate_on_destroy(on_destroy)
      super(**options, &block)
    end

    def live?
      true
    end

    def destroy_filter_model
      return nil if @on_destroy == :reload

      @on_destroy.is_a?(Class) ? @on_destroy.name : @on_destroy
    end

    private

    def validate_on_destroy(policy)
      return policy if policy == :reload
      return policy if policy.is_a?(String) && !policy.empty?
      return policy if policy.is_a?(Class) && policy.name

      raise ArgumentError,
            "on_destroy: expects :reload or a model class/name (e.g. Task or \"Task\"), got #{policy.inspect}"
    end
  end
end
