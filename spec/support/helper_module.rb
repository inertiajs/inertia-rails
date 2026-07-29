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

  # Rails::Rack::Logger writes through Rails.logger; the controller log subscriber
  # writes through ActionController::Base.logger. Swap both to see a whole request.
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
