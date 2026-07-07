# frozen_string_literal: true

module InertiaRails
  class Current < ActiveSupport::CurrentAttributes
    attribute :request, :precognition_called

    # Client-generated per-visit id used for broadcast self-exclusion. It is
    # echoed verbatim into broadcasts, so validate the format before trusting
    # an arbitrary header value.
    LIVE_REQUEST_ID_FORMAT = /\A[0-9a-zA-Z-]{8,64}\z/

    def live_request_id
      id = request&.headers&.[]('X-Inertia-Live-Request-Id')
      id if id&.match?(LIVE_REQUEST_ID_FORMAT)
    end
  end
end
