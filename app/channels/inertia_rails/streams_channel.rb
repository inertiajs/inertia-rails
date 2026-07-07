# frozen_string_literal: true

# Derived from turbo-rails (MIT licensed, Copyright Basecamp).
# https://github.com/hotwired/turbo-rails

# Delivers live-prop broadcasts created (primarily) through <tt>InertiaRails::Broadcastable</tt>.
# A subscription is made for each individual stream. The subscription relies on a <tt>signed_stream_name</tt>
# parameter, generated server-side via <tt>InertiaRails::StreamName#signed_stream_name</tt>. If the signed
# stream name cannot be verified, the subscription is rejected.
#
# For custom authorization, subclass and override <tt>subscribed</tt>, reusing
# <tt>InertiaRails::StreamName::ClassMethods</tt>:
#
#   class CustomStreamsChannel < ActionCable::Channel::Base
#     include InertiaRails::StreamName::ClassMethods
#
#     def subscribed
#       stream_name = verified_stream_name_from_params
#       if stream_name.present? && subscription_allowed?(stream_name)
#         stream_from stream_name
#       else
#         reject
#       end
#     end
#   end
module InertiaRails
  class StreamsChannel < ActionCable::Channel::Base
    include InertiaRails::StreamName::ClassMethods

    def subscribed
      if (stream_name = verified_stream_name_from_params)
        stream_from stream_name
      else
        reject
      end
    end
  end
end
