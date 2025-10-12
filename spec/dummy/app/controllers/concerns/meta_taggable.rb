# frozen_string_literal: true

module MetaTaggable
  extend ActiveSupport::Concern

  included do
    before_action :set_meta_tags, only: :override_tags_from_module
  end

  def set_meta_tags
    inertia_meta
      .add({
             name: 'meta_tag_from_concern',
             content: 'This should be overriden by the controller',
             head_key: 'meta_tag_from_concern',
           })
      .add({
             name: 'unnecessary_tag',
             content: 'This tag will be removed',
             head_key: 'unnecessary_tag',
           })
      .add({
             name: 'please_remove_me',
             content: 'no head_key to target!',
           })
  end
end
