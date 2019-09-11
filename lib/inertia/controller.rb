require_relative "inertia"

module Inertia
  module Controller
    extend ActiveSupport::Concern

    module ClassMethods
      def inertia_share(**args, &block)
        Inertia.instance.share(args) if args
        Inertia.instance.share_block(block) if block
      end
    end
  end
end
