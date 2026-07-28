# frozen_string_literal: true

module InertiaRails
  module DevTools
    class EntryBuilder
      BODY_LIMIT = 256_000
      REDACTED = '[REDACTED]'
      SENSITIVE_HEADERS = %w[
        authorization cookie set-cookie x-csrf-token x-xsrf-token
      ].freeze
      SENSITIVE_KEYS = %w[
        password password_confirmation current_password token _token access_token refresh_token
        secret client_secret api_key
      ].freeze

      def initialize(request:, status:, headers:, body:, id:, batch_id:, started_at:)
        @request = request
        @status = status
        @headers = headers
        @body = body
        @id = id
        @batch_id = batch_id
        @started_at = started_at
        @page = request.get_header(PAGE_ENV_KEY)
      end

      def build
        now = Time.now
        component = page_value('component')
        props, prop_values = build_props

        {
          '__meta' => {
            'id' => @id,
            'tabUuid' => header(TAB_HEADER),
            'batchId' => @batch_id,
            'timestamp' => now.utc.iso8601(3),
            'utime' => now.to_f,
            'method' => @request.request_method,
            'url' => redact_url(@request.url),
            'component' => component,
            'requestType' => request_type(component),
            'status' => @status,
            'redirectLocation' => redirect_location,
            'serverTimingMs' => elapsed_ms,
            'visitId' => header(VISIT_HEADER),
          },
          'http' => {
            'requestHeaders' => request_headers,
            'responseHeaders' => response_headers,
            'requestBody' => request_body,
            'responseBody' => response_body,
          },
          'props' => props,
          'propValues' => prop_values,
          'route' => route,
          'renderSource' => nil,
          'componentPath' => nil,
        }
      end

      private

      def header(name)
        value = @request.headers[name]
        value.is_a?(String) && !value.empty? ? value : nil
      end

      def page_value(key)
        return unless @page.is_a?(Hash)

        @page[key] || @page[key.to_sym]
      end

      def request_type(component)
        return 'precognition' if header('Precognition')
        return component ? 'initial' : 'http' unless header('X-Inertia')
        return 'deferred' if header(DEFERRED_HEADER)
        return 'poll' if header(POLL_HEADER)
        return 'partial' if header('X-Inertia-Partial-Component')
        return 'prefetch' if prefetch?

        'navigate'
      end

      def prefetch?
        [header('Purpose'), header('Sec-Purpose')].compact.any? do |value|
          value.downcase.split(/[;,]\s*/).include?('prefetch')
        end
      end

      def elapsed_ms
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - @started_at) * 1000).round(3)
      end

      def redirect_location
        location = response_header('X-Inertia-Location') || response_header('Location')
        return unless @status.between?(300, 399) || response_header('X-Inertia-Location')

        location
      end

      def request_headers
        @request.env.each_with_object({}) do |(key, value), result|
          name = case key
                 when 'CONTENT_TYPE' then 'Content-Type'
                 when 'CONTENT_LENGTH' then 'Content-Length'
                 else
                   next unless key.start_with?('HTTP_')

                   canonical_header(key.delete_prefix('HTTP_'))
                 end

          result[name] = sensitive_header?(name) ? REDACTED : value.to_s
        end
      end

      def response_headers
        @headers.each_with_object({}) do |(name, value), result|
          normalized_name = canonical_header(name)
          result[normalized_name] = sensitive_header?(name) ? REDACTED : Array(value).join(', ')
        end
      end

      def sensitive_header?(name)
        SENSITIVE_HEADERS.include?(name.to_s.downcase)
      end

      def canonical_header(name)
        name.to_s.tr('_', '-').split('-').map(&:capitalize).join('-')
      end

      def request_body
        return empty_body if %w[GET HEAD].include?(@request.request_method)
        return omitted_body('non-inertia-request') unless header('X-Inertia')

        parameters = @request.request_parameters
        parameters = parameters.except('controller', 'action') if parameters.respond_to?(:except)
        capture_value(parameters)
      rescue StandardError
        omitted_body('unserializable')
      end

      def response_body
        return capture_value(@page) if @page.is_a?(Hash)
        return omitted_body('non-textual') unless textual_response?

        content = response_content
        return omitted_body('streamed') if content.nil?

        if json_response?
          capture_value(JSON.parse(content))
        else
          capture_value(content)
        end
      rescue JSON::ParserError
        capture_value(content)
      end

      def response_content
        chunks = if @body.is_a?(Array)
                   @body
                 elsif @body.respond_to?(:to_ary)
                   @body.to_ary
                 end
        return unless chunks&.all?(String)

        chunks.join
      end

      def textual_response?
        content_type = response_header('Content-Type').to_s.downcase

        content_type.start_with?('text/') ||
          content_type.match?(/json|javascript|xml|x-www-form-urlencoded|svg/)
      end

      def json_response?
        response_header('Content-Type').to_s.downcase.include?('json')
      end

      def capture_value(value)
        normalized = normalize(value)
        encoded = JSON.generate(normalized)
        return omitted_body('too-large') if encoded.bytesize > BODY_LIMIT

        return empty_body if normalized.nil? || normalized == '' || normalized == {} || normalized == []

        {
          'status' => 'present',
          'value' => redact(normalized),
        }
      rescue JSON::GeneratorError, EncodingError
        omitted_body('unserializable')
      end

      def normalize(value)
        JSON.parse(JSON.generate(summarize_uploads(value).as_json))
      end

      def summarize_uploads(value)
        case value
        when Hash
          value.transform_values { |item| summarize_uploads(item) }
        when Array
          value.map { |item| summarize_uploads(item) }
        when ActionDispatch::Http::UploadedFile
          {
            'name' => value.original_filename,
            'contentType' => value.content_type,
            'size' => value.size,
          }
        else
          value
        end
      end

      def redact(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, item), result|
            result[key] = sensitive_key?(key) ? REDACTED : redact(item)
          end
        when Array
          value.map { |item| redact(item) }
        else
          value
        end
      end

      def sensitive_key?(key)
        SENSITIVE_KEYS.include?(key.to_s.downcase)
      end

      def redact_url(url)
        uri = URI.parse(url)
        return url if uri.query.nil?

        pairs = URI.decode_www_form(uri.query).map do |key, value|
          [key, sensitive_key?(key) ? REDACTED : value]
        end
        uri.query = URI.encode_www_form(pairs)
        uri.to_s
      rescue URI::InvalidURIError
        url
      end

      def build_props
        values = page_value('props')
        values = {} unless values.is_a?(Hash)
        normalized_values = redact(normalize(values))
        metadata = {}

        normalized_values.each_key do |key|
          metadata[key.to_s] = {
            'shared' => shared_props.include?(key.to_s),
            'inertiaType' => nil,
          }
        end

        add_deferred_metadata(metadata)
        add_array_metadata(metadata, 'mergeProps', 'merge', 'mergeDirection' => 'append')
        add_array_metadata(metadata, 'prependProps', 'merge', 'mergeDirection' => 'prepend')
        add_array_metadata(metadata, 'deepMergeProps', 'merge', 'deepMerge' => true)
        add_hash_metadata(metadata, 'scrollProps', 'scroll')
        add_once_metadata(metadata)
        add_flag_metadata(metadata, 'rescuedProps', 'rescued')

        parse_header_values('X-Inertia-Reset').each do |path|
          ensure_prop(metadata, path)['reset'] = true
        end

        prop_values = metadata.each_key.with_object({}) do |path, result|
          found, value = value_at_path(normalized_values, path)
          result[path] = value if found
        end

        [metadata, prop_values]
      rescue JSON::GeneratorError, EncodingError
        [{}, {}]
      end

      def shared_props
        Array(page_value('sharedProps')).map(&:to_s)
      end

      def add_deferred_metadata(metadata)
        deferred = page_value('deferredProps')
        return unless deferred.is_a?(Hash)

        deferred.each do |group, paths|
          Array(paths).each do |path|
            ensure_prop(metadata, path).merge!(
              'inertiaType' => 'defer',
              'deferGroup' => group.to_s
            )
          end
        end
      end

      def add_array_metadata(metadata, page_key, inertia_type, extra = {})
        Array(page_value(page_key)).each do |path|
          ensure_prop(metadata, path).merge!({ 'inertiaType' => inertia_type }.merge(extra))
        end
      end

      def add_hash_metadata(metadata, page_key, inertia_type)
        value = page_value(page_key)
        return unless value.is_a?(Hash)

        value.each_key do |path|
          ensure_prop(metadata, path).merge!('inertiaType' => inertia_type, 'mergeDirection' => 'append')
        end
      end

      def add_once_metadata(metadata)
        value = page_value('onceProps')
        return unless value.is_a?(Hash)

        value.each_value do |details|
          path = details.is_a?(Hash) ? details['prop'] || details[:prop] : nil
          ensure_prop(metadata, path).merge!('inertiaType' => 'once', 'once' => true) if path
        end
      end

      def add_flag_metadata(metadata, page_key, flag)
        Array(page_value(page_key)).each { |path| ensure_prop(metadata, path)[flag] = true }
      end

      def ensure_prop(metadata, path)
        metadata[path.to_s] ||= { 'shared' => shared_props.include?(path.to_s), 'inertiaType' => nil }
      end

      def parse_header_values(name)
        header(name).to_s.split(',').map(&:strip).reject(&:empty?)
      end

      def value_at_path(values, path)
        current = values

        path.to_s.split('.').each do |part|
          key = current.is_a?(Array) ? Integer(part, exception: false) : part
          return [false, nil] unless key && current.respond_to?(:key?) && current.key?(key)

          current = current[key]
        end

        [true, current]
      end

      def route
        controller = @request.get_header('action_controller.instance')
        action = if controller
                   "#{controller.class.name}##{controller.action_name}"
                 elsif @request.path_parameters[:controller]
                   "#{@request.path_parameters[:controller]}##{@request.path_parameters[:action]}"
                 end

        {
          'name' => @request.get_header('action_dispatch.route_name'),
          'uri' => @request.get_header('action_dispatch.route_uri_pattern') || @request.path,
          'action' => action,
        }
      end

      def response_header(name)
        pair = @headers.find { |key, _value| key.to_s.casecmp?(name) }
        pair&.last
      end

      def empty_body
        { 'status' => 'empty' }
      end

      def omitted_body(reason)
        { 'status' => 'omitted', 'reason' => reason }
      end
    end
  end
end
