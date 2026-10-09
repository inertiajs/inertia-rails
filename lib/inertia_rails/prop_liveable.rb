# frozen_string_literal: true

module InertiaRails
  module PropLiveable
    # Takes its options out, so a prop that hands the rest to Rails.cache (`InertiaRails.cache`) never sees them.
    def initialize(*args, **props, &block)
      @live_streams = LiveStream.names(props.delete(:live)) if props.key?(:live)
      @live_throttle = live_throttle_from(props.delete(:throttle))

      super

      raise ArgumentError, 'Live updates are not supported on merge props' if live? && try(:merge?)
    end

    def live?
      !@live_streams.nil?
    end

    def live_metadata
      listeners = @live_streams.map do |name|
        { channel: { name: LiveStream.signed(name), type: 'public' }, events: [LiveStream::EVENT] }
      end

      { listeners: listeners, throttle: @live_throttle }.compact
    end

    private

    def live_throttle_from(throttle)
      return if throttle.nil?
      raise ArgumentError, '`throttle:` needs `live:`' unless live?

      throttle.is_a?(ActiveSupport::Duration) ? (throttle.to_f * 1000).round : throttle
    end
  end
end
