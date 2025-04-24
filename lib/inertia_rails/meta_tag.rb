module InertiaRails
  class MetaTag
    # Copied from Inertia.js
    UNARY_TAGS = %i[
      area base br col embed hr img input keygen link meta param source track wbr
    ].freeze

    def initialize(tag_name: :meta, head_key: nil, raw: false, **tag_data)
      @tag_name = tag_name.to_s.downcase.to_sym
      @head_key = head_key || generate_head_key(tag_name, tag_data)
      @raw = raw
      @tag_data = tag_data.each_with_object({}) do |(key, value), result|
        transformed_key = key.to_s.tr('_', '-').to_sym
        result[transformed_key] = value
      end
    end

    def as_json(**options)
      {
        :tagName => @tag_name,
        :"head-key" => @head_key,
        **@tag_data
      }
    end

    def to_tag(tag_helper)
      data = @tag_data.deep_dup.merge({
        inertia: @head_key
      })

      inner_content = case @tag_name
                      when *UNARY_TAGS
                        nil
                      when :script
                        handle_script_content(data.delete(:content))
                      else
                        data.delete(:content)
                      end

      tag_helper.public_send(@tag_name, *[inner_content].compact, **data)
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
  end
end
