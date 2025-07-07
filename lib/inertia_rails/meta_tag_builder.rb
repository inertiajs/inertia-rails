# frozen_string_literal: true

module InertiaRails
  class MetaTagBuilder
    attr_reader :meta_tags

    def initialize(controller)
      @controller = controller
      @meta_tags = []
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

      @meta_tags.reject! do |tag|
        if block_given?
          block.call(tag)
        else
          tag[:head_key] == head_key
        end
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

      @meta_tags.reject! do |existing_tag|
        duplicate?(existing_tag, new_tag)
      end

      @meta_tags << new_tag
    end

    def duplicate?(existing_tag, new_tag)
      existing_tag[:head_key] == new_tag[:head_key] ||
        (new_tag[:tag_name] == :title && existing_tag[:tag_name] == :title)
    end
  end
end
