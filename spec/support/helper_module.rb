# frozen_string_literal: true

module HelperModule
  def self.included(base)
    base.extend(ClassMethods)
  end

  def with_forgery_protection
    orig = ActionController::Base.allow_forgery_protection
    begin
      ActionController::Base.allow_forgery_protection = true
      yield if block_given?
    ensure
      ActionController::Base.allow_forgery_protection = orig
    end
  end

  # Rails 8.2+ appends Sec-Fetch-Site in its own after_action.
  def vary_header_without_sec_fetch_site
    response.headers['Vary'].to_s.split(/,\s*/).reject { |v| v == 'Sec-Fetch-Site' }.join(', ')
  end

  # Rails' request log and the controller log use different loggers.
  def capture_log
    io = StringIO.new
    original = [Rails.logger, ActionController::Base.logger]
    Rails.logger = ActionController::Base.logger = ActiveSupport::Logger.new(io, level: Logger::DEBUG)
    yield
    io.string
  ensure
    Rails.logger, ActionController::Base.logger = original
  end

  def with_env(**env)
    orig = ENV.to_h
    begin
      ENV.replace(env)
      yield if block_given?
    ensure
      ENV.replace(orig)
    end
  end

  module ClassMethods
    def with_devtools_config(**settings)
      around do |example|
        config = InertiaRails::Devtools.config
        original = settings.keys.to_h { |name| [name, config.public_send(name)] }
        settings.each { |name, value| config.public_send(:"#{name}=", value) }
        example.run
      ensure
        original.each { |name, value| config.public_send(:"#{name}=", value) }
      end
    end

    def with_inertia_config(**props)
      around do |example|
        config = InertiaRails.configuration
        orig_options = config.send(:options).dup
        config.merge!(InertiaRails::Configuration.new(**props))
        example.run
      ensure
        config.instance_variable_set(:@options, orig_options)
      end
    end
  end
end
