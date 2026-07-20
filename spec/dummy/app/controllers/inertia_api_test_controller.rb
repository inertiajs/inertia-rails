# frozen_string_literal: true

# Inherits from ActionController::API, which does not receive the
# InertiaRails::Controller mixin (only ActionController::Base does).
class InertiaApiTestController < ActionController::API
  def index
    render json: { ok: true }
  end

  def external_redirect
    redirect_to 'http://external-website.com/some_path', allow_other_host: true
  end
end
