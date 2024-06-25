# frozen_string_literal: true

module InertiaRails
  class Configuration
    DEFAULTS = {
      default_render: false,

      # Let Rails decide which layout should be used based on the controller configuration.
      layout: true,

      deep_merge_shared_data: false,
      ssr_enabled: false,
      ssr_url: 'http://localhost:13714',
      version: nil,
    }.freeze

    OPTION_NAMES = DEFAULTS.keys.freeze

    protected attr_reader :options

    def initialize(**attrs)
      @options = attrs.extract!(*OPTION_NAMES)

      unless attrs.empty?
        raise ArgumentError, "Unknown options for #{self.class}: #{attrs.keys}"
      end
    end

    def to_h
      @options.to_h
    end

    def merge(config)
      Configuration.new(**@options.merge(config.options))
    end

    OPTION_NAMES.each do |option|
      define_method(option) {
        value = @options[option]
        value.respond_to?(:call) ? value.call : value
      }
      define_method("#{option}=") { |value|
        @options[option] = value
      }
    end

    def self.default
      new(**DEFAULTS)
    end
  end
end
