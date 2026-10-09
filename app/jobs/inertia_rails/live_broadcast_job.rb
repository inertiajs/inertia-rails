# frozen_string_literal: true

module InertiaRails
  class LiveBroadcastJob < ActiveJob::Base
    def perform(names, socket_id)
      LiveBroadcast.publish(names, socket_id: socket_id)
    end
  end
end
