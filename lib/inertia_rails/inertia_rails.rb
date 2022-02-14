# Needed for `thread_mattr_accessor`
require 'active_support/core_ext/module/attribute_accessors_per_thread'
require 'inertia_rails/lazy'

module InertiaRails
  thread_mattr_accessor :threadsafe_shared_plain_data
  thread_mattr_accessor :threadsafe_shared_blocks
  thread_mattr_accessor :threadsafe_html_headers

  def self.configure
    yield(Configuration)
  end

  # "Getters"
  def self.shared_data(controller)
    shared_plain_data.merge!(evaluated_blocks(controller, shared_blocks))
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

  def self.html_headers
    self.threadsafe_html_headers || []
  end

  # "Setters"
  def self.share(**args)
    self.shared_plain_data = self.shared_plain_data.merge(args)
  end

  def self.share_block(block)
    self.shared_blocks = self.shared_blocks + [block]
  end

  def self.html_headers=(headers)
    self.threadsafe_html_headers = headers
  end

  def self.reset!
    self.shared_plain_data = {}
    self.shared_blocks = []
    self.html_headers = []
  end

  def self.lazy(value = nil, &block)
    InertiaRails::Lazy.new(value, &block)
  end

  private

  module Configuration
    mattr_accessor(:layout) { 'application' }
    mattr_accessor(:version) { nil }
    mattr_accessor(:ssr_enabled) { false }
    mattr_accessor(:ssr_url) { 'http://localhost:13714' }

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

  def self.evaluated_blocks(controller,  blocks)
    blocks.flat_map { |block| controller.instance_exec(&block) }.reduce(&:merge) || {}
  end
end
