# Needed for `thread_mattr_accessor`
require 'active_support/core_ext/module/attribute_accessors_per_thread'
require 'inertia_rails/lazy'

module InertiaRails
  def self.configure
    yield(Configuration)
  end

  def self.version
    Configuration.evaluated_version
  end

  def self.layout
    Configuration.layout
  end

  def self.lazy(value = nil, &block)
    InertiaRails::Lazy.new(value, &block)
  end

  private

  module Configuration
    mattr_accessor(:layout) { 'application' }
    mattr_accessor(:version) { nil }

    def self.evaluated_version
      self.version.respond_to?(:call) ? self.version.call : self.version
    end
  end

  # Getters and setters to provide default values for the threadsafe attributes
  def self.shared_plain_data
    self.threadsafe_shared_plain_data || {}
  end

  def self.shared_plain_data=(val)
    self.threadsafe_shared_plain_data = val
  end

  def self.shared_blocks
    self.threadsafe_shared_blocks || []
  end

  def self.shared_blocks=(val)
    self.threadsafe_shared_blocks = val
  end
end
