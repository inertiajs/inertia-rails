# frozen_string_literal: true

class InertiaSessionContinuityTestController < ApplicationController
  def initialize_session
    render inertia: 'TestNewSessionComponent'
  end

  def submit_form_to_test_csrf
    render inertia: 'TestComponent'
  end

  def clear_session
    session.clear

    redirect_to initialize_session_path
  end
end
