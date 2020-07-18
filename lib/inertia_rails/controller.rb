require_relative "inertia_rails"

module InertiaRails
  module Controller
    extend ActiveSupport::Concern

    included do
      error_sharing = proc do
        # :inertia_errors are deleted from the session by the middleware
        if @_request && session[:inertia_errors].present?
          { errors: session[:inertia_errors] }
        else
          {}
        end
      end

      if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('5.2.0')
        class_attribute :shared_plain_data, default: {}
        class_attribute :shared_blocks, default: [error_sharing]
      else
        # In older Rails there is no `default` for class_attribute. This was
        # introduced with Rails 5.2: https://github.com/rails/rails/pull/29270
        class_attribute :shared_plain_data
        class_attribute :shared_blocks

        self.shared_plain_data = {}
        self.shared_blocks = [error_sharing]
      end
    end

    class_methods do
      def inertia_share(hash = nil, &block)
        share_plain_data(hash) if hash
        share_block(&block) if block_given?
      end

      def share_plain_data(hash)
        self.shared_plain_data = shared_plain_data.merge(hash)
      end

      def share_block(&block)
        self.shared_blocks = shared_blocks + [ block ]
      end
    end

    def shared_data
      shared_plain_data.merge(evaluated_blocks)
    end

    def redirect_to(options = {}, response_options = {})
      capture_inertia_errors(response_options)
      super(options, response_options)
    end

    def redirect_back(fallback_location:, allow_other_host: true, **options)
      capture_inertia_errors(options)
      super(
        fallback_location: fallback_location,
        allow_other_host: allow_other_host,
        **options,
      )
    end

    private

    def inertia_location(url)
      headers['X-Inertia-Location'] = url
      head :conflict
    end

    def capture_inertia_errors(options)
      if (inertia_errors = options.dig(:inertia, :errors))
        session[:inertia_errors] = inertia_errors
      end
    end

    private

    def evaluated_blocks
      shared_blocks.map { |block| instance_exec(&block) }.reduce(&:merge) || {}
    end
  end
end
