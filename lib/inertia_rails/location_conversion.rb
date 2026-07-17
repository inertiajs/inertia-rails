# frozen_string_literal: true

module InertiaRails
  # Converts a cross-origin redirect into an Inertia location response (409 Conflict +
  # X-Inertia-Location), which makes the client perform a `window.location` visit:
  # XHR follows redirects transparently, so the follow-up request would fail CORS checks.
  class LocationConversion
    # Method-preserving 307/308 are excluded: a full page visit is always a GET.
    STATUSES = [301, 302, 303].freeze

    def initialize(status, headers, request, configuration)
      @status = status
      @headers = headers
      @request = request
      @configuration = configuration
    end

    def convertible?
      @configuration.convert_external_redirects &&
        STATUSES.include?(@status) &&
        external_origin?(@headers['Location'])
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
