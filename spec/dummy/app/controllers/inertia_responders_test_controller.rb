# frozen_string_literal: true

require 'responders'

Thing = Class.new

class InertiaRespondersTestController < ApplicationController
  self.responder = ActionController::Responder
  respond_to :html

  def redirect_test
    respond_with Thing.new, location: '/foo'
  end
end
