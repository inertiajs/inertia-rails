require_relative "inertia_rails"

module InertiaRails
  module Controller
    extend ActiveSupport::Concern

    module ClassMethods
      def inertia_share(**args, &block)
        InertiaRails.share(args) if args
        InertiaRails.share_block(block) if block
      end
    end
  end
end
