# frozen_string_literal: true

module InertiaRails
  module Helper
    def inertia_ssr_head
      head = controller.instance_variable_get('@_inertia_ssr_head')
      return head unless head

      safe_join([head, inertia_devtools_tag].compact, "\n")
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

      root =
        if config.use_script_element_for_initial_page
          safe_join([
                      tag.script(page.to_json.html_safe, **inertia_script_options('data-page': id)),
                      tag.div(id: id)
                    ], "\n")
        else
          tag.div(id: id, 'data-page': page.to_json)
        end

      safe_join([root, inertia_devtools_tag].compact, "\n")
    end

    # Lets the DevTools extension pick up the entry id for the initial page load,
    # before any XHR has happened.
    def inertia_devtools_tag
      recorder = InertiaRails::Devtools.recorder(controller.request)
      return unless recorder

      tag.script(
        recorder.id.to_json.html_safe,
        **inertia_script_options('data-inertia-devtools-id': '')
      )
    end

    private

    def inertia_script_options(**attributes)
      options = attributes.merge(type: 'application/json')
      return options unless respond_to?(:content_security_policy_nonce, true)

      nonce = content_security_policy_nonce
      nonce.present? ? options.merge(nonce: nonce) : options
    end
  end
end
