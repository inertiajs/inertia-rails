# frozen_string_literal: true

module InertiaRails
  # Converts a redirect into an Inertia location response (409 Conflict +
  # X-Inertia-Location), which makes the client perform a `window.location` visit.
  #
  # Cross-origin redirects convert automatically: XHR follows redirects
  # transparently, so the follow-up request would fail CORS checks. Same-origin
  # redirects convert only when marked with `inertia: { full_page: true }` —
  # a Location header doesn't reveal whether its target renders an Inertia page.
  class LocationConversion
    # Method-preserving 307/308 are excluded: a full page visit is always a GET.
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

    # Mutates the headers in place to keep the rest of the response, notably
    # Set-Cookie (which matters mid-OAuth).
    def convert!(body)
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
