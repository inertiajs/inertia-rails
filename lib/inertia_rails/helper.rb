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

  def inertia_rendering?
    controller.instance_variable_get("@_inertia_rendering")
  end

  def inertia_page
    controller.instance_variable_get("@_inertia_page")
  end

  def inertia_meta_tags
    meta_tag_data = (inertia_page || {}).dig(:props, :_inertia_meta) || []

    meta_tags = meta_tag_data.map do |inertia_meta_tag|
      inertia_meta_tag.to_tag(tag)
    end

    safe_join(meta_tags, "\n")
  end
end
