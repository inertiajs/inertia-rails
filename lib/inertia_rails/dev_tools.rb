# frozen_string_literal: true

require 'securerandom'
require 'time'

require_relative 'dev_tools/store'
require_relative 'dev_tools/entry_builder'
require_relative 'dev_tools/middleware'

module InertiaRails
  module DevTools
    ID_HEADER = 'X-Inertia-Devtools-Id'
    OUTGOING_PARENT_HEADER = 'X-Inertia-Devtools-Parent-Out'
    INCOMING_PARENT_HEADER = 'X-Inertia-Devtools-Parent'
    TAB_HEADER = 'X-Inertia-Devtools-Tab'
    VISIT_HEADER = 'X-Inertia-Devtools-Visit'
    DEFERRED_HEADER = 'X-Inertia-Devtools-Deferred'
    POLL_HEADER = 'X-Inertia-Devtools-Poll'

    PAGE_ENV_KEY = 'inertia_rails.devtools.page'

    class << self
      def enabled?
        !!InertiaRails.configuration.devtools_enabled
      rescue StandardError
        false
      end

      def authorized?(request)
        authorizer = InertiaRails.configuration.devtools_authorize

        authorizer.respond_to?(:call) && !!authorizer.call(request)
      rescue StandardError
        false
      end

      def capture_page(request, page)
        return unless enabled?

        request.set_header(PAGE_ENV_KEY, page)
      end

      def store
        @store ||= Store.new
      end

      def reset!
        @store&.clear
      end
    end
  end
end
