# frozen_string_literal: true

class ExceptionsAppTestController < ApplicationController
  def boom
    raise 'boom'
  end
end
