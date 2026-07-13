# frozen_string_literal: true

require 'responders'

class InertiaRespondersTestController < ApplicationController
  self.responder = ActionController::Responder
  respond_to :html

  def redirect_test
    respond_with Object.new, location: '/foo'
  end
end
