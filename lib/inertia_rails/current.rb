# frozen_string_literal: true

module InertiaRails
  class Current < ActiveSupport::CurrentAttributes
    attribute :request, :precognition_called
  end
end
