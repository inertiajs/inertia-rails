require_relative "inertia_rails"
require_relative "helper"

module InertiaRails
  module Controller
    extend ActiveSupport::Concern

    included do
      before_action do
        # :inertia_errors are deleted from the session by the middleware
        InertiaRails.share(errors: session[:inertia_errors]) if session[:inertia_errors].present?
      end
      helper ::InertiaRails::Helper
    end

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

    def redirect_to(options = {}, response_options = {})
      if (inertia_errors = response_options.fetch(:inertia, {}).fetch(:errors, nil))
        session[:inertia_errors] = inertia_errors
      end

      super(options, response_options)
    end
  end
end
