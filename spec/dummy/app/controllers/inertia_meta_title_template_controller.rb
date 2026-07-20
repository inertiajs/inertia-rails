# frozen_string_literal: true

class InertiaMetaTitleTemplateController < ApplicationController
  # Calls a private controller method to prove the template runs in controller context.
  inertia_config(meta_title_template: ->(title) { title ? "#{title} - #{app_name}" : app_name })

  def with_title
    render inertia: 'TestComponent', meta: [{ title: 'The Page' }]
  end

  def default_title
    render inertia: 'TestComponent'
  end

  private

  def app_name
    'Inertia App'
  end
end
