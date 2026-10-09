# frozen_string_literal: true

require 'rails_helper'
require 'open3'

RSpec.describe 'Live props and the frameworks they use' do
  # A fresh process each, since other specs load Action Cable and Active Job.
  def boot(script)
    output, status = Open3.capture2e(RbConfig.ruby, '-e', <<~RUBY)
      require 'logger' # same workaround as rails_helper, for Rails < 7.1
      ENV['RAILS_ENV'] = 'test'
      #{script}
      print 'booted'
    RUBY

    expect(status).to be_success, output
    expect(output).to end_with('booted')
  end

  let(:environment) { File.expand_path('../dummy/config/environment', __dir__).inspect }

  it 'eager loads an app without Action Cable and Active Job' do
    boot(<<~RUBY)
      require #{environment}
      abort 'Action Cable is loaded' if defined?(ActionCable)
      abort 'Active Job is loaded' if defined?(ActiveJob)
      Rails.autoloaders.main.eager_load
    RUBY
  end

  it 'eager loads an app without them on the classic autoloader', if: Rails::VERSION::MAJOR < 7 do
    boot(<<~RUBY)
      require #{File.expand_path('../dummy/config/application', __dir__).inspect}
      Rails.application.config.autoloader = :classic
      Rails.application.initialize!
      Rails.application.config.eager_load_namespaces.each(&:eager_load!)
    RUBY
  end

  it 'eager loads the channel and job, and adds the model macros, in an app with them' do
    boot(<<~RUBY)
      require #{File.expand_path('../dummy/config/boot', __dir__).inspect}
      require 'rails'
      require 'active_job/railtie'
      require 'action_cable/engine'
      require #{environment}
      require 'active_record' # without the railtie, which would connect to a database
      Rails.autoloaders.main.eager_load
      abort 'channel not loaded' if InertiaRails.autoload?(:LiveChannel)
      abort 'job not loaded' if InertiaRails.autoload?(:LiveBroadcastJob)
      abort 'no model macros' unless ActiveRecord::Base.include?(InertiaRails::LiveBroadcastable)
    RUBY
  end
end
