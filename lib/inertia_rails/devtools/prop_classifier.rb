# frozen_string_literal: true

module InertiaRails
  module Devtools
    class PropClassifier
      def initialize(deferred_request:)
        @deferred_request = deferred_request
      end

      def classify(prop)
        return { inertiaType: nil } unless prop.is_a?(BaseProp)

        {
          inertiaType: inertia_type(prop),
          deferGroup: defer_group(prop),
          once: prop.try(:once?),
          mergeDirection: merge_direction(prop),
          deepMerge: deep_merge?(prop),
        }
      end

      private

      def inertia_type(prop)
        case prop
        when AlwaysProp then 'always'
        when DeferProp then 'defer' unless reloaded_by_hand?(prop)
        when ScrollProp then 'scroll'
        when OptionalProp, LazyProp then 'optional'
        when MergeProp then 'merge'
        when OnceProp then 'once'
        end
      end

      def defer_group(prop)
        return unless prop.try(:deferred?)
        return if reloaded_by_hand?(prop)

        prop.group
      end

      # A deferred prop reloaded by hand, not by the client's deferred fetch, counts as plain.
      def reloaded_by_hand?(prop)
        prop.is_a?(DeferProp) && !@deferred_request
      end

      # Matching items on a key updates them in place, so it counts as a deep merge, as in Laravel.
      def deep_merge?(prop)
        return false unless prop.try(:merge?)

        prop.deep_merge? || prop.match_on.present?
      end

      def merge_direction(prop)
        return unless prop.try(:merge?)

        prepend = prop.prepends_at_root? || (prop.prepends_at_paths.any? && prop.appends_at_paths.none?)
        prepend ? 'prepend' : 'append'
      end
    end
  end
end
