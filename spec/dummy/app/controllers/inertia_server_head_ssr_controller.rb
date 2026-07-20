# frozen_string_literal: true

class InertiaServerHeadSsrController < ApplicationController
  inertia_config(server_head: true, layout: 'meta', ssr_enabled: true, version: '1.0')

  def basic
    render inertia: 'TestComponent', meta: [
      { tag_name: 'title', inner_content: 'The Inertia title' }
    ]
  end
end
