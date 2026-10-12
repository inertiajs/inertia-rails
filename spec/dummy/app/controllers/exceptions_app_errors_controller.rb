# frozen_string_literal: true

class ExceptionsAppErrorsController < ApplicationController
  include InertiaRails::ErrorPage

  def show
    render inertia: 'ErrorPage', props: { status: status }
  end
end
