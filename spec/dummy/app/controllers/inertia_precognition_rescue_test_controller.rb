# frozen_string_literal: true

class InertiaPrecognitionRescueTestController < InertiaPrecognitionTestController
  rescue_from(StandardError) { head :internal_server_error }
end
