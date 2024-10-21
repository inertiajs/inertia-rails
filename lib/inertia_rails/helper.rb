require_relative 'inertia_rails'

module InertiaRails::Helper
  def inertia_ssr_head
    controller.instance_variable_get("@_inertia_ssr_head")
  end

  def inertia_headers
    InertiaRails.deprecator.warn(
      "`inertia_headers` is deprecated and will be removed in InertiaRails 4.0, use `inertia_ssr_head` instead."
    )
    inertia_ssr_head
  end
end
