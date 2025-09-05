# frozen_string_literal: true

class InertiaMultithreadedShareController < ApplicationController
  inertia_share name: 'Michael'
  inertia_share has_goat_status: true

  def share_multithreaded
    sleep 1
    render inertia: 'ShareTestComponent'
  end

  def share_multithreaded_error
    raise StandardError
  end
end
