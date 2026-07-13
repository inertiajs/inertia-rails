# frozen_string_literal: true

module InertiaRails
  module PropOnceable
    attr_reader :once_key, :once_expires_in

    def initialize(**props, &block)
      @once = props.fetch(:once, false)
      @once_key = props[:key]
      @once_expires_in = props[:expires_in]
      @fresh = props.fetch(:fresh, false)

      super
    end

    def once?
      @once
    end

    def fresh?
      @fresh
    end

    def expires_at
      return nil unless @once_expires_in

      timestamp = case @once_expires_in
                  when ActiveSupport::Duration
                    (Time.current + @once_expires_in).to_f
                  when Numeric
                    Time.current.to_f + @once_expires_in
                  else
                    raise ArgumentError, "Invalid `expires_in` value: #{@once_expires_in.inspect}"
                  end

      (timestamp * 1000).to_i
    end
  end
end
