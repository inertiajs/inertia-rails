module InertiaRails
  class MetaTag
    # Copied from Inertia.js
    UNARY_TAGS = %i[
      area base br col embed hr img input keygen link meta param source track wbr
    ].freeze

    def initialize(tag_name: nil, head_key: nil, raw: false, **tag_data)
      @is_shortened_title_tag = shortened_title_tag?(tag_name, tag_data)
      @tag_name = determine_tag_name(tag_name)
      @head_key = head_key || generate_head_key(@tag_name, tag_data)
      @raw = raw
      @tag_data = build_tag_data(tag_data)
    end

    def as_json(**options)
      {
        :tagName => @tag_name,
        :headKey => @head_key,
        **@tag_data.transform_keys { |k| k.to_s.camelize(:lower).to_sym }
      }
    end

    def to_tag(tag_helper)
      data = @tag_data.deep_dup
        .merge({ inertia: @head_key })

      inner_content = case @tag_name
                      when *UNARY_TAGS
                        nil
                      when :script
                        handle_script_content(data.delete(:inner_content))
                      else
                        data.delete(:inner_content)
                      end

      tag_helper.public_send(@tag_name, *[inner_content].compact, **data.transform_keys { |k| k.to_s.tr('_','-').to_sym })
    end

    private

    def generate_head_key(tag_name, tag_data)
      signature = tag_data.sort.map { |k, v| "#{k}=#{v}" }.join("&")
      digest = Digest::MD5.hexdigest(signature)[0, 8]
      "#{tag_name}-#{digest}"
    end

    def handle_script_content(content)
      case content
      when String
        @raw ? content.html_safe : ERB::Util.html_escape(content)
      else
        ERB::Util.json_escape(content.to_json).html_safe
      end
    end

    def shortened_title_tag?(tag_name, tag_data)
      tag_name.nil? && tag_data.keys == [:title]
    end

    def determine_tag_name(tag_name)
      return :title if @is_shortened_title_tag
      return :meta if tag_name.nil?
      tag_name.downcase.to_sym
    end

    def build_tag_data(tag_data)
      return { inner_content: tag_data[:title] } if @is_shortened_title_tag
      tag_data
    end
  end
end
