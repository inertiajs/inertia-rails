# frozen_string_literal: true

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
      config = controller.send(:inertia_configuration)
      meta_tag_data = (inertia_page || {}).dig(:props, config.meta_prop) || []
      attribute = config.head_attribute

      meta_tags = meta_tag_data.map do |inertia_meta_tag|
        next inertia_meta_tag if inertia_meta_tag.is_a?(String)

        inertia_meta_tag.to_tag(tag, inertia_attribute: attribute)
      end

      safe_join(meta_tags, "\n")
    end

    def inertia_root(id: nil, page: inertia_page)
      config = controller.send(:inertia_configuration)
      id ||= config.root_dom_id

      if config.use_script_element_for_initial_page
        script_options = { 'data-page': id, type: 'application/json' }
        if respond_to?(:content_security_policy_nonce, true)
          nonce = content_security_policy_nonce
          script_options[:nonce] = nonce if nonce.present?
        end

        safe_join([
                    tag.script(page.to_json.html_safe, **script_options),
                    tag.div(id: id)
                  ], "\n")
      else
        tag.div(id: id, 'data-page': page.to_json)
      end
    end
  end
end
