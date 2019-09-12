require_relative "inertia"

module Inertia
  module Controller
    extend ActiveSupport::Concern

    module ClassMethods
      def inertia_share(**args, &block)
        Inertia.share(args) if args
        Inertia.share_block(block) if block
      end
    end
  end
end
