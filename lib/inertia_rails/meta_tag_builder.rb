# frozen_string_literal: true

module InertiaRails
  class MetaTagBuilder
    def initialize(controller)
      @controller = controller
      @meta_tags = {}
    end

    def meta_tags
      @meta_tags.values
    end

    def add(meta_tag)
      if meta_tag.is_a?(Array)
        meta_tag.each { |tag| add(tag) }
      elsif meta_tag.is_a?(Hash)
        add_new_tag(meta_tag)
      else
        raise ArgumentError, 'Meta tag must be a Hash or Array of Hashes'
      end

      self
    end

    def remove(head_key = nil, &block)
      raise ArgumentError, 'Cannot provide both head_key and a block' if head_key && block_given?
      raise ArgumentError, 'Must provide either head_key or a block' if head_key.nil? && !block_given?

      if head_key
        @meta_tags.delete(head_key)
      else
        @meta_tags.reject! { |_, tag| block.call(tag) }
      end

      self
    end

    def clear
      @meta_tags.clear

      self
    end

    private

    def add_new_tag(new_tag_data)
      new_tag = InertiaRails::MetaTag.new(**new_tag_data)
      @meta_tags[new_tag[:head_key]] = new_tag
    end
  end
end
