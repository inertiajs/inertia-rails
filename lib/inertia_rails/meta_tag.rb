module InertiaRails
  class MetaTag
    # Copied from Inertia.js
    UNARY_TAGS = %i[
      area base br col embed hr img input keygen link meta param source track wbr
    ].freeze

    def initialize(tag_name: nil, head_key: nil, raw: false, allow_duplicates: false, **tag_data)
      @is_shortened_title_tag = shortened_title_tag?(tag_name, tag_data)
      @tag_name = determine_tag_name(tag_name)
      @allow_duplicates = allow_duplicates
      @raw = raw
      @tag_data = build_tag_data(tag_data)
      @head_key = head_key || generate_head_key
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

    def [](key)
      return @tag_name if key == :tag_name
      return @head_key if key == :head_key
      @tag_data[key.to_sym]
    end

    private

    def generate_head_key
      generate_meta_head_key || "#{@tag_name}-#{tag_digest}"
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
      tag_data.deep_symbolize_keys
    end

    def tag_digest
      signature = @tag_data.sort.map { |k, v| "#{k}=#{v}" }.join("&")
      Digest::MD5.hexdigest(signature)[0, 8]
    end

    def generate_meta_head_key
      return unless @tag_name == :meta
      return "meta-charset" if @tag_data.key?(:charset)

      [:name, :property, :http_equiv].each do |key|
        next unless @tag_data.key?(key)

        return [
          "meta",
          key,
          @tag_data[key].parameterize,
          @allow_duplicates ? tag_digest : nil
        ].compact.join("-")
      end

      nil
    end
  end
end
