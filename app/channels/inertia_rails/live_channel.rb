# frozen_string_literal: true

module InertiaRails
  # A valid signed stream name is the only check, as with Turbo's streams channel.
  module LiveChannel
    private

    def subscribed
      if (name = LiveStream.verified(params[:stream]))
        stream_from name
      else
        reject
      end
    end
  end
end
