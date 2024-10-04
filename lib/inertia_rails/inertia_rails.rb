# Needed for `thread_mattr_accessor`
require 'active_support/core_ext/module/attribute_accessors_per_thread'
require 'inertia_rails/ignore_first_load_prop'
require 'inertia_rails/defer_prop'
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
    InertiaRails::IgnoreFirstLoadProp.new(value, &block)
  end

  def self.defer(value = nil, group = nil, &block)
    InertiaRails::DeferProp.new(value, group, &block)
  end
end
