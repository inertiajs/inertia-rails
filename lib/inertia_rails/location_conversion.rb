# frozen_string_literal: true

module InertiaRails
  # Decides whether a redirect must become an Inertia location response
  # (409 Conflict + X-Inertia-Location, which makes the client perform a full
  # `window.location` visit) and performs the conversion.
  #
  # XHR requests follow redirects transparently, so an Inertia client can
  # never see a redirect to another origin: the follow-up request fails CORS
  # checks. Cross-origin redirects therefore convert automatically. Same-origin
  # redirects to non-Inertia endpoints cannot be detected — a Location header
  # does not reveal whether its target renders an Inertia page — so they
  # convert only when marked with `redirect_to url, inertia: { full_page: true }`.
  class LocationConversion
    # Redirect statuses eligible for conversion. Method-preserving 307/308 are
    # excluded: a `window.location` visit cannot preserve the HTTP method.
    STATUSES = [301, 302, 303].freeze

    FULL_PAGE_REDIRECT_KEY = 'inertia_rails.full_page_redirect'

    def self.mark_full_page!(env, status)
      unless STATUSES.include?(status)
        raise ArgumentError, "`inertia: { full_page: true }` requires a 301, 302, or 303 redirect (got #{status}): " \
                             'a full page visit always issues a GET, so it cannot preserve the HTTP method.'
      end

      env[FULL_PAGE_REDIRECT_KEY] = true
    end

    def initialize(env, status, headers, request, configuration)
      @env = env
      @status = status
      @headers = headers
      @request = request
      @configuration = configuration
    end

    def convertible?
      STATUSES.include?(@status) && (external_redirect? || full_page_redirect?)
    end

    # Mutates the response triple in place to preserve other headers, notably
    # Set-Cookie (which matters mid-OAuth). Capitalized header literals work
    # on both Rack generations because Rails-originated responses carry a
    # case-insensitive Rack::Headers on Rack 3 and a capitalized plain hash
    # on Rack 2; redirects from raw Rack endpoints (plain lowercase hashes
    # on Rack 3) pass through unconverted.
    def to_response(body)
      @headers['X-Inertia-Location'] = @headers.delete('Location')
      @headers.delete('Content-Type')
      @headers.delete('Content-Length')
      body.close if body.respond_to?(:close)

      [409, @headers, []]
    end

    private

    def external_redirect?
      @configuration.convert_external_redirects && external_origin?(@headers['Location'])
    end

    def full_page_redirect?
      @env[FULL_PAGE_REDIRECT_KEY].present? && @headers['Location'].present?
    end

    def external_origin?(location)
      return false if location.blank?

      uri = URI.parse(location)
      return false if uri.host.blank?

      scheme = uri.scheme || @request.scheme
      port = uri.port || (scheme == 'https' ? 443 : 80)

      scheme != @request.scheme || !uri.host.casecmp?(@request.host) || port != @request.port
    rescue URI::InvalidURIError
      false
    end
  end
end
