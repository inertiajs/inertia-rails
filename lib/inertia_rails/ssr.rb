# frozen_string_literal: true

module InertiaRails
  module SSR
    class << self
      def vite_dev_server_url
        # vite_rails: TCP probe
        if defined?(ViteRuby) && ViteRuby.instance.dev_server_running?
          config = ViteRuby.config
          return "#{config.protocol}://#{config.host_with_port}"
        end

        # rails_vite + jsbundling: file-based
        path = Rails.root.join('tmp/rails-vite.json')
        JSON.parse(path.read)['url'] if path.exist?
      rescue StandardError
        nil
      end

      def vite_dev_server_running?
        !vite_dev_server_url.nil?
      end
    end
  end
end
