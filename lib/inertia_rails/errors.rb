# frozen_string_literal: true

module InertiaRails
  class Error < StandardError; end

  class DoublePrecognitionError < StandardError
    def initialize
      super('You can only call precognition once per action, use a form object to validate multiple models.')
    end
  end

  class SSRError < Error
    attr_reader :type, :hint, :browser_api, :stack, :source_location

    def initialize(message = nil, type: nil, hint: nil, browser_api: nil, stack: nil, source_location: nil)
      @type = type
      @hint = hint
      @browser_api = browser_api
      @stack = stack
      @source_location = source_location
      super(message)
    end

    def self.from_response(body)
      new(
        body['error'] || 'Unknown SSR error',
        type: body['type'],
        hint: body['hint'],
        browser_api: body['browserApi'],
        stack: body['stack'],
        source_location: body['sourceLocation']
      )
    end

    def self.from_exception(exception)
      # Ruby has no `cause=`; `raise` is the only thing that sets it, from `$!`.
      # Raising here — while the original exception is still being handled —
      # lets the wrapper carry it, so error trackers can walk the chain on both
      # the fallback and `ssr_raise_on_error` paths. Outside a rescue block
      # `$!` is nil and `cause` is simply nil.
      raise new(exception.message, type: 'connection')
    rescue SSRError => e
      e.set_backtrace(exception.backtrace)
      e
    end
  end
end
