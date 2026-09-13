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
