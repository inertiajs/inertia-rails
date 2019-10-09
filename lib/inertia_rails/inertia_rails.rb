module InertiaRails
  mattr_accessor :shared_plain_data, default: {}
  mattr_accessor :shared_blocks, default: []

  def self.configure
    yield(Configuration)
  end

  # "Getters"
  def self.shared_data
    shared_plain_data.merge!(evaluated_blocks(shared_blocks))
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
    mattr_accessor :layout, default: 'application'
    mattr_accessor :version, default: nil

    def self.evaluated_version
      version.respond_to?(:call) ? version.call : version
    end
  end

  def self.evaluated_blocks(blocks)
    blocks.flat_map(&:call).reduce(&:merge) || {}
  end
end
