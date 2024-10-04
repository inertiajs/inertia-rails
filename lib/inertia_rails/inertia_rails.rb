# Needed for `thread_mattr_accessor`
require 'active_support/core_ext/module/attribute_accessors_per_thread'
require 'inertia_rails/ignore_first_load_prop'

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

  def self.ssr_enabled?
    Configuration.ssr_enabled
  end

  def self.ssr_url
    Configuration.ssr_url
  end

  def self.default_render?
    Configuration.default_render
  end

  def self.deep_merge_shared_data?
    Configuration.deep_merge_shared_data
  end

  def self.lazy(value = nil, &block)
    InertiaRails::IgnoreFirstLoadProp.new(value, &block)
  end

  private

  module Configuration
    mattr_accessor(:layout) { nil }
    mattr_accessor(:version) { nil }
    mattr_accessor(:ssr_enabled) { false }
    mattr_accessor(:ssr_url) { 'http://localhost:13714' }
    mattr_accessor(:default_render) { false }
    mattr_accessor(:deep_merge_shared_data) { false }

    def self.evaluated_version
      self.version.respond_to?(:call) ? self.version.call : self.version
    end
  end
end
