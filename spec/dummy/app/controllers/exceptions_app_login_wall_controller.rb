# frozen_string_literal: true

class ExceptionsAppLoginWallController < ExceptionsAppErrorsController
  before_action { redirect_to '/login' }
end
