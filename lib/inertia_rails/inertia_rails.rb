# Needed for `thread_mattr_accessor`
require 'active_support/core_ext/module/attribute_accessors_per_thread'

module InertiaRails
  thread_mattr_accessor :threadsafe_shared_plain_data
  thread_mattr_accessor :threadsafe_shared_blocks

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

  # "Setters"
  def self.share(**args)
    self.shared_plain_data = self.shared_plain_data.merge(args)
  end

  def self.share_block(block)
    self.shared_blocks = self.shared_blocks + [block]
  end

  def self.reset!
    self.shared_plain_data = {}
    self.shared_blocks = []
  end

  private

  module Configuration
    thread_mattr_accessor :threadsafe_layout
    thread_mattr_accessor :threadsafe_version

    def self.evaluated_version
      self.version.respond_to?(:call) ? self.version.call : self.version
    end

    def self.layout
      self.threadsafe_layout || 'application'
    end

    def self.layout=(val)
      self.threadsafe_layout = val
    end

    def self.version
      self.threadsafe_version
    end

    def self.version=(val)
      self.threadsafe_version = val
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
