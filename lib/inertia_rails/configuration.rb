# frozen_string_literal: true

module InertiaRails
  class Configuration
    DEFAULTS = {
      # Whether to combine hashes with the same keys instead of replacing them.
      deep_merge_shared_data: false,

      # Overrides Rails default rendering behavior to render using Inertia by default.
      default_render: false,

      # Allows the user to hook into the default rendering behavior and change it to fit their needs
      component_path_resolver: ->(path:, action:) { "#{path}/#{action}" },

      # DEPRECATED: Let Rails decide which layout should be used based on the
      # controller configuration.
      layout: true,

      # Whether to encrypt the history state in the client.
      encrypt_history: false,

      # SSR options.
      ssr_enabled: false,
      ssr_url: 'http://localhost:13714',

      # Used to detect version drift between server and client.
      version: nil,
    }.freeze

    OPTION_NAMES = DEFAULTS.keys.freeze

    def self.default
      new(**DEFAULTS).with_env_options
    end

    def initialize(controller: nil, **attrs)
      @controller = controller
      @options = attrs.extract!(*OPTION_NAMES)

      unless attrs.empty?
        raise ArgumentError, "Unknown options for #{self.class}: #{attrs.keys}"
      end
    end

    def bind_controller(controller)
      Configuration.new(**options, controller: controller)
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

    # Internal: Finalizes the configuration for a specific controller.
    def with_defaults(config)
      @options = config.options.merge(@options)
      freeze
    end

    def component_path_resolver(path:, action:)
      @options[:component_path_resolver].call(path: path, action: action)
    end

    OPTION_NAMES.each do |option|
      define_method(option) {
        evaluate_option options[option]
      } unless method_defined?(option)
      define_method("#{option}=") { |value|
        @options[option] = value
      }
    end

    protected attr_reader :controller

    def options
      @with_env_options ? @options.merge(env_options) : @options
    end
    protected :options

    def with_env_options
      @with_env_options = true
      self
    end

    private

    def evaluate_option(value)
      return value unless value.respond_to?(:call)
      return value.call unless controller
      controller.instance_exec(&value)
    end

    def env_options
      @env_options ||= DEFAULTS.keys.each_with_object({}) do |key, hash|
        value = ENV.fetch("INERTIA_#{key.to_s.upcase}", nil)
        next if value.nil?

        hash[key] = %w[true false].include?(value) ? value == 'true' : value
      end
    end
  end
end
