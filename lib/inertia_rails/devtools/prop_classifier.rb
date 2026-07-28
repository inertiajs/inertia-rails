# frozen_string_literal: true

module InertiaRails
  module Devtools
    # Maps a prop wrapper to the metadata the DevTools panel badges it with.
    class PropClassifier
      def initialize(deferred_request:, reset_keys: [])
        @deferred_request = deferred_request
        @reset_keys = reset_keys
      end

      def classify(path, prop)
        {
          inertiaType: inertia_type(prop),
          deferGroup: defer_group(prop),
          reset: @reset_keys.include?(path),
          once: prop.try(:once?) || false,
          mergeDirection: merge_direction(prop),
          deepMerge: deep_merge?(prop),
        }
      end

      private

      # A DeferProp only counts as deferred when it is delivered by a deferred
      # request. Resolved on a manual partial reload it behaves like a regular prop.
      def deferred_delivery?(prop)
        prop.is_a?(DeferProp) && @deferred_request
      end

      def inertia_type(prop)
        case prop
        when AlwaysProp then 'always'
        when DeferProp then deferred_delivery?(prop) ? 'defer' : nil
        when ScrollProp then 'scroll'
        when OptionalProp, LazyProp then 'optional'
        when MergeProp then 'merge'
        when OnceProp then 'once'
        end
      end

      def defer_group(prop)
        return unless prop.try(:deferred?)
        return if prop.is_a?(DeferProp) && !deferred_delivery?(prop)

        prop.try(:group)
      end

      # Deep merge covers both `deep_merge` and `match_on`, which upserts array
      # items on a key rather than blindly appending them.
      def deep_merge?(prop)
        return false unless prop.try(:merge?)

        prop.deep_merge? || prop.match_on.present?
      end

      # Read from the wrapper rather than the page object, which records deep
      # merges under `deepMergeProps` without a direction.
      def merge_direction(prop)
        return unless prop.try(:merge?)

        prepends = prop.prepends_at_paths.any?
        appends = prop.appends_at_paths.any?

        prop.prepends_at_root? || (prepends && !appends) ? 'prepend' : 'append'
      end
    end
  end
end
