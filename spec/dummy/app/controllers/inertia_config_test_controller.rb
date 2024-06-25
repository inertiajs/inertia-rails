class InertiaConfigTestController < ApplicationController
  inertia_config(
    ssr_enabled: true,
    deep_merge_shared_data: true,
    ssr_enabled: true,
    ssr_url: "http://localhost:7777",
    layout: "test",
    version: "2.0",
  )

  def configuration
    render json: inertia_configuration.to_h
  end
end
