# frozen_string_literal: true

module InertiaRails
  class Error < StandardError; end

  class DoublePrecognitionError < StandardError
    def initialize
      super('You can only call precognition once per action, use a form object to validate multiple models.')
    end
  end
end
