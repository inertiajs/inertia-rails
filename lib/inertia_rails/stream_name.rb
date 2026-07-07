# frozen_string_literal: true

# Derived from turbo-rails (MIT licensed, Copyright Basecamp).
# https://github.com/hotwired/turbo-rails

# Stream names are how we identify which updates should go to which users. All streams run over the same
# <tt>InertiaRails::StreamsChannel</tt>, but each with their own subscription. Since stream names are exposed
# directly to the client, we need to ensure that the name isn't tampered with, so the names are signed upon
# generation and verified upon receipt. All verification happens through <tt>InertiaRails.signed_stream_verifier</tt>.
module InertiaRails
  module StreamName
    extend self

    # Used by <tt>InertiaRails::StreamsChannel</tt> to verify a signed stream name.
    def verified_stream_name(signed_stream_name)
      InertiaRails.signed_stream_verifier.verified(signed_stream_name)
    end

    # Generates a signed stream name from the given streamables.
    def signed_stream_name(streamables)
      InertiaRails.signed_stream_verifier.generate(stream_name_from(streamables))
    end

    def stream_name_from(streamables)
      if streamables.is_a?(Array)
        streamables.compact.map { |s| stream_name_from(s) }.join(':')
      else
        streamables.try(:to_gid_param) || streamables.to_param
      end
    end

    # Can be used by custom channels to obtain a signed stream name from <tt>params</tt>.
    module ClassMethods
      def verified_stream_name_from_params
        InertiaRails::StreamName.verified_stream_name(params[:signed_stream_name])
      end
    end
  end
end
