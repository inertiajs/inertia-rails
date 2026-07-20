# frozen_string_literal: true

# Inherits from ActionController::API, which does not receive the
# InertiaRails::Controller mixin (only ActionController::Base does).
class InertiaApiTestController < ActionController::API
  def index
    render json: { ok: true }
  end
end
