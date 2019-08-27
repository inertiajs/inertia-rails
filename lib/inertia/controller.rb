module Inertia
  class Controller
    extend ActiveSupport::Concern

    module class_methods
      def inertia_share(**args, &block)
        Inertia.instance.share(args) if args
        Inertia.instance.share_block(block) if block
      end
    end
  end
end
