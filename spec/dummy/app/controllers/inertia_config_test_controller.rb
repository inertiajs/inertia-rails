# frozen_string_literal: true

class InertiaConfigTestController < ApplicationController
  inertia_config(
    deep_merge_shared_data: true,
    ssr_enabled: true,
    ssr_url: 'http://localhost:7777',
    layout: 'test',
    version: '1.0',
    encrypt_history: false
  )

  # Test that modules included in the same class can also call it.
  inertia_config(
    version: '2.0'
  )

  def configuration
    render json: inertia_configuration.send(:options)
  end
end
