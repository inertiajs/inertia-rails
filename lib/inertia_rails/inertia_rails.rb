module InertiaRails
  thread_mattr_accessor :shared_plain_data
  thread_mattr_accessor :shared_blocks

  def self.configure
    yield(Configuration)
  end

  # "Getters"
  def self.shared_data(controller)
    threadsafe_shared_plain_data.merge!(evaluated_blocks(controller, threadsafe_shared_blocks))
  end

  def self.version
    Configuration.evaluated_version
  end

  def self.layout
    Configuration.layout
  end

  # "Setters"
  def self.share(**args)
    self.shared_plain_data = threadsafe_shared_plain_data.merge(args)
  end

  def self.share_block(block)
    self.shared_blocks = threadsafe_shared_blocks + [block]
  end

  def self.reset!
    self.shared_plain_data = {}
    self.shared_blocks = []
  end

  private

  module Configuration
    mattr_accessor(:layout) { 'application' }
    mattr_accessor(:version) { nil }

    def self.evaluated_version
      self.version.respond_to?(:call) ? self.version.call : self.version
    end
  end

  def self.evaluated_blocks(controller,  blocks)
    blocks.flat_map { |block| controller.instance_exec(&block) }.reduce(&:merge) || {}
  end

  # thread_mattr_accessor doesn't accept :default as an option, and since the method
  # is actually defined in the context of Thread.current, we can't do something like:
  # def self.shared_plain_data
  #   @@shared_plain_data || {}
  # end
  def self.threadsafe_shared_plain_data
    self.shared_plain_data || {}
  end

  def self.threadsafe_shared_blocks
    self.shared_blocks || []
  end
end
