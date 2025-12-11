# frozen_string_literal: true

require_relative 'inertia_rails'

module InertiaRails
  module Helper
    def inertia_ssr_head
      controller.instance_variable_get('@_inertia_ssr_head')
    end

    def inertia_headers
      InertiaRails.deprecator.warn(
        '`inertia_headers` is deprecated and will be removed in InertiaRails 4.0, use `inertia_ssr_head` instead.'
      )
      inertia_ssr_head
    end

    def inertia_rendering?
      controller.instance_variable_get('@_inertia_rendering')
    end

    def inertia_page
      controller.instance_variable_get('@_inertia_page')
    end

    def inertia_meta_tags
      meta_tag_data = (inertia_page || {}).dig(:props, :_inertia_meta) || []

      meta_tags = meta_tag_data.map do |inertia_meta_tag|
        inertia_meta_tag.to_tag(tag)
      end

      safe_join(meta_tags, "\n")
    end

    def inertia_root(id: nil, page: inertia_page)
      config = controller.send(:inertia_configuration)
      id ||= config.root_dom_id

      if config.use_script_element_for_initial_page
        safe_join([
                    tag.script(page.to_json.html_safe, 'data-page': id, type: 'application/json'),
                    tag.div(id: id)
                  ], "\n")
      else
        tag.div(id: id, 'data-page': page.to_json)
      end
    end
  end
end
