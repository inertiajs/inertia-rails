# frozen_string_literal: true

require 'securerandom'

module InertiaRails
  module Devtools
    # Entry ids double as the sort key: every "newest first" listing and every
    # eviction decision compares ids lexicographically, so they must be monotonic
    # even for two requests landing in the same millisecond.
    module Ulid
      ENCODING = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
      TIME_LENGTH = 10
      RANDOM_LENGTH = 16
      RANDOM_MAX = (1 << 80) - 1
      PATTERN = /\A[0-7][#{ENCODING}]{25}\z/

      @mutex = Mutex.new
      @last_time = 0
      @last_random = 0

      class << self
        def generate(time = Time.now)
          milliseconds, randomness = next_pair((time.to_f * 1000).floor)

          encode(milliseconds, TIME_LENGTH) + encode(randomness, RANDOM_LENGTH)
        end

        def valid?(value)
          value.is_a?(String) && PATTERN.match?(value)
        end

        private

        def next_pair(milliseconds)
          @mutex.synchronize do
            if milliseconds > @last_time
              @last_time = milliseconds
              @last_random = SecureRandom.random_number(RANDOM_MAX)
            elsif @last_random >= RANDOM_MAX
              # Incrementing would wrap the randomness and sort backwards, so
              # borrow from the next millisecond instead.
              @last_time += 1
              @last_random = SecureRandom.random_number(RANDOM_MAX)
            else
              @last_random += 1
            end

            [@last_time, @last_random]
          end
        end

        def encode(value, length)
          Array.new(length) do
            char = ENCODING[value & 0x1f]
            value >>= 5
            char
          end.reverse!.join
        end
      end
    end
  end
end
