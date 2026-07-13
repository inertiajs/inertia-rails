# frozen_string_literal: true

module InertiaRails
  module PropMergeable
    attr_reader :match_on, :appends_at_paths, :prepends_at_paths

    def initialize(**props, &block)
      raise ArgumentError, 'Cannot set both `deep_merge` and `merge` to true' if props[:deep_merge] && props[:merge]

      @deep_merge = props.fetch(:deep_merge, false)
      @merge = props[:merge] || @deep_merge
      @match_on = props[:match_on].nil? ? nil : Array(props[:match_on])
      @appends_at_paths = []
      @prepends_at_paths = []
      @append = true

      append(props[:append]) if props.key?(:append)
      prepend(props[:prepend]) if props.key?(:prepend)

      super
    end

    def appends_at_root?
      @append && merges_at_root?
    end

    def prepends_at_root?
      !@append && merges_at_root?
    end

    def merges_at_root?
      merge? && appends_at_paths.none? && prepends_at_paths.none?
    end

    def merge?
      @merge
    end

    def deep_merge?
      @deep_merge
    end

    private

    def append(path, match_on: nil)
      case path
      when TrueClass, FalseClass
        @append = path
      when String
        @appends_at_paths << path
      when Array
        @appends_at_paths += path
      when Hash
        @match_on ||= []
        path.each do |key, value|
          @appends_at_paths << key.to_s
          @match_on << "#{key}.#{value}" if value
        end
      end

      (@match_on ||= []) << "#{path}.#{match_on}" if match_on && path.is_a?(String)
    end

    def prepend(path, match_on: nil)
      case path
      when TrueClass, FalseClass
        @append = !path
      when String
        @prepends_at_paths << path
      when Array
        @prepends_at_paths += path
      when Hash
        @match_on ||= []
        path.each do |key, value|
          @prepends_at_paths << key.to_s
          @match_on << "#{key}.#{value}" if value
        end
      end

      (@match_on ||= []) << "#{path}.#{match_on}" if match_on && path.is_a?(String)
    end
  end
end
