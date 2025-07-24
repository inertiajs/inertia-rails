# frozen_string_literal: true

module InertiaRails
  class MetaTag
    # See https://github.com/rails/rails/blob/v8.0.0/actionview/lib/action_view/helpers/tag_helper.rb#L84-L97
    UNARY_TAGS = %i[
      area base br col embed hr img input keygen link meta source track wbr
    ].freeze

    LD_JSON_TYPE = 'application/ld+json'
    DEFAULT_SCRIPT_TYPE = 'text/plain'

    def initialize(tag_name: nil, head_key: nil, allow_duplicates: false, type: nil, **tag_data)
      if shortened_title_tag?(tag_name, tag_data)
        @tag_name = :title
        @tag_data = { inner_content: tag_data[:title] }
      else
        @tag_name = tag_name.nil? ? :meta : tag_name.to_sym
        @tag_data = tag_data.symbolize_keys
      end
      @tag_type = determine_tag_type(type)
      @allow_duplicates = allow_duplicates
      @head_key = @tag_name == :title ? 'title' : (head_key || generate_head_key)
    end

    def as_json(_options = nil)
      {
        tagName: @tag_name,
        headKey: @head_key,
        type: @tag_type,
      }.tap do |result|
        result.merge!(@tag_data.transform_keys { |k| k.to_s.camelize(:lower).to_sym })
        result.compact_blank!
      end
    end

    def to_tag(tag_helper)
      data = @tag_data.merge(type: @tag_type, inertia: @head_key)

      inner_content =
        if @tag_name == :script
          tag_script_inner_content(data.delete(:inner_content))
        else
          data.delete(:inner_content)
        end

      if UNARY_TAGS.include? @tag_name
        tag_helper.public_send(@tag_name, **data.transform_keys { |k| k.to_s.tr('_', '-').to_sym })
      else
        tag_helper.public_send(@tag_name, inner_content, **data.transform_keys { |k| k.to_s.tr('_', '-').to_sym })
      end
    end

    def [](key)
      key = key.to_sym
      return @tag_name if key == :tag_name
      return @head_key if key == :head_key
      return @tag_type if key == :type

      @tag_data[key]
    end

    private

    def tag_script_inner_content(content)
      case content
      when Hash, Array
        ERB::Util.json_escape(content.to_json).html_safe
      else
        content
      end
    end

    def shortened_title_tag?(tag_name, tag_data)
      tag_name.nil? && tag_data.keys == [:title]
    end

    def determine_tag_type(type)
      return type unless @tag_name == :script

      type == LD_JSON_TYPE ? LD_JSON_TYPE : DEFAULT_SCRIPT_TYPE
    end

    def generate_head_key
      generate_meta_head_key || "#{@tag_name}-#{tag_digest}"
    end

    def tag_digest
      signature = @tag_data.sort.map { |k, v| "#{k}=#{v}" }.join('&')
      Digest::MD5.hexdigest(signature)[0, 8]
    end

    def generate_meta_head_key
      return unless @tag_name == :meta
      return 'meta-charset' if @tag_data.key?(:charset)

      %i[name property http_equiv].each do |key|
        next unless @tag_data.key?(key)

        return [
          'meta',
          key,
          @tag_data[key].parameterize,
          @allow_duplicates ? tag_digest : nil
        ].compact.join('-')
      end

      nil
    end
  end
end
