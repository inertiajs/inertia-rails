# frozen_string_literal: true

# Derived from turbo-rails (MIT licensed, Copyright Basecamp).
# https://github.com/hotwired/turbo-rails

require 'concurrent/scheduled_task'

module InertiaRails
  class Debouncer
    DEFAULT_DELAY = 0.5

    attr_reader :delay, :scheduled_task

    def initialize(delay: DEFAULT_DELAY)
      @delay = delay
      @scheduled_task = nil
    end

    def debounce(&block)
      scheduled_task&.cancel unless scheduled_task&.complete?
      @scheduled_task = Concurrent::ScheduledTask.execute(delay, &block)
    end

    def wait
      scheduled_task&.wait(wait_timeout)
    end

    private

    def wait_timeout
      delay + 1
    end
  end

  # A debouncer that executes immediately without delays or background threads.
  # This doesn't debounce at all, but is safe to use in tests.
  class ImmediateDebouncer # :nodoc:
    def initialize(delay: Debouncer::DEFAULT_DELAY)
    end

    def debounce(&block)
      block.call
    end

    def wait
    end

    def complete?
      true
    end
  end

  # A decorated debouncer that will store instances in the current thread clearing them
  # after the debounced logic triggers.
  class ThreadDebouncer
    delegate :wait, to: :debouncer

    class_attribute :debouncer_class, default: Debouncer

    def self.for(key, delay: Debouncer::DEFAULT_DELAY)
      Thread.current[key] ||= new(key, Thread.current, delay: delay)
    end

    private_class_method :new

    def initialize(key, thread, delay:)
      @key = key
      @debouncer = debouncer_class.new(delay: delay)
      @thread = thread
    end

    def debounce
      debouncer.debounce do
        yield
      ensure
        thread[key] = nil
      end
    end

    private

    attr_reader :key, :debouncer, :thread
  end
end
