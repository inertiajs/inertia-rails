require_relative "inertia_rails"

module InertiaRails
  module Controller
    extend ActiveSupport::Concern

    included do
      before_action do
        # :inertia_errors are deleted from the session by the middleware
        InertiaRails.share(errors: session[:inertia_errors]) if session[:inertia_errors].present?
      end
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

    def inertia_redirect_to(options = {}, response_options = {})
      if (errors = response_options.delete(:errors))
        session[:inertia_errors] = errors
      end

      redirect_to(options, response_options)
    end
  end
end
