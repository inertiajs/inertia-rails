# frozen_string_literal: true

class InertiaEncryptHistoryController < ApplicationController
  inertia_config(
    encrypt_history: -> { action_name != 'default_config' }
  )

  def default_config
    render inertia: 'TestComponent'
  end

  def encrypt_history
    render inertia: 'TestComponent'
  end

  def override_config
    render inertia: 'TestComponent', encrypt_history: false
  end

  def clear_history
    render inertia: 'TestComponent', clear_history: true
  end

  def clear_history_after_redirect
    redirect_to :empty_test, inertia: { clear_history: true }
  end
end
