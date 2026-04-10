# frozen_string_literal: true

module InertiaRails
  class SSRRenderer
    def initialize(configuration, page:, cache: nil)
      @configuration = configuration
      @page = page
      @cache = cache
    end

    def render
      return unless bundle_exists?

      if (cache_options = cache_options_hash)
        InertiaRails.cache_store.fetch(cache_key, **cache_options) { request }
      else
        request
      end
    rescue InertiaRails::SSRError => e
      handle_error(e)
    rescue StandardError => e
      handle_error(InertiaRails::SSRError.from_exception(e))
    end

    private

    def page_json
      @page_json ||= @page.to_json
    end

    def request
      uri = URI.parse(url)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.post(uri.request_uri, page_json, 'Content-Type' => 'application/json')
      end

      unless response.is_a?(Net::HTTPSuccess)
        body = begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          {}
        end
        body['error'] ||= "SSR server returned #{response.code}"
        raise InertiaRails::SSRError.from_response(body)
      end

      JSON.parse(response.body)
    end

    def handle_error(error)
      Rails.logger.error("[inertia-rails] SSR render failed: #{error.message}")
      @configuration.on_ssr_error&.call(error, @page)
      raise error if @configuration.ssr_raise_on_error

      nil
    end

    def cache_options_hash
      return if vite_dev_server_url

      raw = @cache.nil? ? @configuration.ssr_cache : @cache
      case raw
      when true then {}
      when Hash then raw
      end
    end

    def cache_key
      "inertia_ssr/#{Digest::MD5.hexdigest(page_json)}"
    end

    def url
      if @configuration.ssr_url&.end_with?('/render', '/__inertia_ssr')
        @configuration.ssr_url
      elsif @configuration.ssr_url
        "#{@configuration.ssr_url}/render"
      elsif (dev_url = vite_dev_server_url)
        "#{dev_url}/__inertia_ssr"
      else
        "#{InertiaRails::Configuration::DEFAULT_SSR_URL}/render"
      end
    end

    def vite_dev_server_url
      return @vite_dev_server_url if defined?(@vite_dev_server_url)

      @vite_dev_server_url = InertiaRails::SSR.vite_dev_server_url
    end

    def bundle_exists?
      return true if vite_dev_server_url

      bundle = @configuration.ssr_bundle
      return true if bundle.nil?

      Array(bundle).any? { |path| File.exist?(path) }
    end
  end
end
