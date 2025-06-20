class InertiaMetaController < ApplicationController
  include MetaTaggable

  before_action :set_description_meta_tag, only: :from_before_filter

  def basic
    render inertia: 'TestComponent', meta: [
      { name: 'description', content: 'Inertia rules', head_key: 'first_head_key' },
      { tag_name: 'title', inner_content: 'The Inertia title', head_key: 'second_head_key' },
      { http_equiv: 'content-security-policy', content: "default-src 'self';", head_key: 'third_head_key'},
    ]
  end

  def multiple_title_tags
    render inertia: 'TestComponent', meta: [
      { tag_name: 'title', inner_content: 'The Inertia title', head_key: 'first_head_key' },
      { title: 'The second Inertia title', head_key: 'second_head_key' }
    ]
  end

  def from_before_filter
    render inertia: 'TestComponent'
  end

  def with_duplicate_head_keys
    render inertia: 'TestComponent', meta: [
      { name: 'description', content: 'This is a description', head_key: 'duplicate_key' },
      { name: 'description', content: 'This is another description', head_key: 'duplicate_key' },
    ]
  end

  def override_tags_from_module
    inertia_meta.add({
      name: 'meta_tag_from_concern',
      content: 'This is overriden by the controller',
      head_key: 'meta_tag_from_concern',
    })

    inertia_meta.remove('unnecessary_tag')

    inertia_meta.remove do |tag|
      tag[:name] == 'please_remove_me'
    end

    render inertia: 'TestComponent'
  end

  protected

  def set_description_meta_tag
    inertia_meta.add({
      name: 'description',
      content: 'This is a description set from a before filter',
      head_key: 'before_filter_tag'
    })
  end
end
