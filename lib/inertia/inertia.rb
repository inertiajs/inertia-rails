module Inertia
  class Inertia
    attr_reader :config 
    include Singleton
  
    def self.configure
      yield(self.instance.config)
    end
  
    def initialize
      @blocks = []
      @config = Configuration.new
      @shared_data = {}
    end
  
    def share(**args)
      @shared_data.merge!(args)
    end
  
    def share_block(block)
      @blocks.push(block)
    end
  
    def shared_data
      @shared_data.merge evaluated_blocks
    end
  
    def self.version
      self.instance.config.version
    end
  
    def self.layout
      self.instance.config.layout
    end
  
    private 
  
    def evaluated_blocks
      @blocks.flat_map(&:call).reduce(&:merge) || {}
    end
  
    class Configuration
      attr_accessor :layout
  
      def initialize
        @version = nil
        @layout = 'application'
      end
  
      def version
        @version.respond_to?(:call) ? @version.call : @version
      end
  
      def version=(v)
        @version = v
      end
    end
  end  
end
