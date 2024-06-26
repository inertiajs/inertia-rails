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

    protected attr_reader :controller
    protected attr_reader :options

    def initialize(controller: nil, **attrs)
      @controller = controller
      @options = attrs.extract!(*OPTION_NAMES)

      unless attrs.empty?
        raise ArgumentError, "Unknown options for #{self.class}: #{attrs.keys}"
      end
    end

    def bind_controller(controller)
      Configuration.new(**@options, controller: controller)
    end

    def freeze
      @options.freeze
      super
    end

    def merge!(config)
      @options.merge!(config.options)
      self
    end

    def merge(config)
      Configuration.new(**@options.merge(config.options))
    end

    OPTION_NAMES.each do |option|
      define_method(option) {
        evaluate_option @options[option]
      }
      define_method("#{option}=") { |value|
        @options[option] = value
      }
    end

    def self.default
      new(**DEFAULTS)
    end

  private

    def evaluate_option(value)
      return value unless value.respond_to?(:call)
      return value.call unless controller
      controller.instance_exec(&value)
    end
  end
end
