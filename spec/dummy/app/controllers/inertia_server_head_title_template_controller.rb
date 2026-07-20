# frozen_string_literal: true

class InertiaServerHeadTitleTemplateController < ApplicationController
  inertia_config(
    server_head: true,
    layout: 'meta',
    meta_title_template: ->(title) { title ? "#{title} - Inertia App" : 'Inertia App' }
  )

  def basic
    render inertia: 'TestComponent', meta: [
      { title: 'The Page' },
      { name: 'description', content: 'Inertia rules', head_key: 'desc_key' }
    ]
  end

  def default_title
    render inertia: 'TestComponent'
  end
end
