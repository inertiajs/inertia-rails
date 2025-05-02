class InertiaMetaController < ApplicationController
  def basic
    render inertia: 'TestComponent', meta: [
      { name: 'description', content: 'Inertia rules', head_key: 'first_head_key' },
      { tag_name: 'title', inner_content: 'The Inertia title', head_key: 'second_head_key' },
      { http_equiv: 'content-security-policy', content: "default-src 'self';", head_key: 'third_head_key'},
    ]
  end
end
