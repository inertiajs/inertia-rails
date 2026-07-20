# frozen_string_literal: true

class InertiaMetaTitleTemplateInvalidController < ApplicationController
  inertia_config(meta_title_template: '%s - Inertia App')

  def basic
    render inertia: 'TestComponent', meta: [{ title: 'The Page' }]
  end
end
