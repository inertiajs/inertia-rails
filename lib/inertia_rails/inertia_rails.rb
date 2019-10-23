module InertiaRails
  mattr_accessor(:shared_plain_data) { Hash.new }
  mattr_accessor(:shared_blocks) { [] }

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
    shared_plain_data.merge!(args)
  end

  def self.share_block(block)
    shared_blocks.push(block)
  end

  private

  module Configuration
    mattr_accessor(:layout) { 'application' }
    mattr_accessor(:version) { nil }

    def self.evaluated_version
      version.respond_to?(:call) ? version.call : version
    end
  end

  def self.evaluated_blocks(controller,  blocks)
    blocks.flat_map { |block| controller.instance_exec(&block) }.reduce(&:merge) || {}
  end
end
