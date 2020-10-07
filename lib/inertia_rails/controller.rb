require_relative "inertia_rails"

module InertiaRails
  module Controller
    extend ActiveSupport::Concern

    module ClassMethods
      def inertia_share(**args, &block)
        before_action do
          InertiaRails.share(**args) if args
          InertiaRails.share_block(block) if block
        end
      end
    end

    def inertia_location(url)
      headers['X-Inertia-Location'] = url
      head :conflict
    end
  end
end
