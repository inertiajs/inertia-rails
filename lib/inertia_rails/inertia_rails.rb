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
    InertiaRails::Lazy.new(value, &block)
  end

  # TODO: Handle html headers
  def self.html_headers
    self.threadsafe_html_headers || []
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
