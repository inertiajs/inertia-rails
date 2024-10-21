# Needed for `thread_mattr_accessor`
require 'active_support/core_ext/module/attribute_accessors_per_thread'
require 'inertia_rails/lazy'
require 'inertia_rails/configuration'

module InertiaRails
  CONFIGURATION = Configuration.default

  def self.configure
    yield(CONFIGURATION)
  end

  def self.configuration
    CONFIGURATION
  end

  def self.lazy(value = nil, &block)
    InertiaRails::Lazy.new(value, &block)
  end
end
