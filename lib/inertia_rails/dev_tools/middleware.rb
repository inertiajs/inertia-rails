# frozen_string_literal: true

module InertiaRails
  module DevTools
    class Middleware
      ENTRIES_PATH = %r{\A/_inertia/devtools/entries(?:/([^/]+))?\z}
      ID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)

        return endpoint_response(request) if devtools_path?(request.path)

        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        status, headers, body = @app.call(env)
        return [status, headers, body] unless DevTools.enabled? && DevTools.authorized?(request)

        record(request, status, headers, body, started_at)
      rescue StandardError => e
        raise if status.nil?

        Rails.logger&.warn("[inertia-rails] DevTools recorder skipped an entry: #{e.class}: #{e.message}")
        [status, headers, body]
      end

      private

      def record(request, status, headers, body, started_at)
        id = SecureRandom.uuid
        batch_id = request.headers['X-Inertia'] ? present_header(request, INCOMING_PARENT_HEADER) : nil
        outgoing_parent = prefetch?(request) ? id : batch_id || id
        inject_initial_id = initial_html_response?(request, status, headers)
        entry_headers = headers.to_h.dup

        entry_headers[ID_HEADER] = id
        entry_headers[OUTGOING_PARENT_HEADER] = outgoing_parent
        delete_injected_body_headers(entry_headers) if inject_initial_id

        entry = EntryBuilder.new(
          request: request,
          status: status,
          headers: entry_headers,
          body: body,
          id: id,
          batch_id: batch_id,
          started_at: started_at
        ).build
        DevTools.store.record(entry)

        headers[ID_HEADER] = id
        headers[OUTGOING_PARENT_HEADER] = outgoing_parent

        if inject_initial_id
          delete_injected_body_headers(headers)
          body = InjectingBody.new(body, devtools_tag(id))
        end

        [status, headers, body]
      end

      def endpoint_response(request)
        return json_response({ message: 'Not found.' }, 404) unless DevTools.enabled?
        return json_response({ message: 'Forbidden.' }, 403) unless DevTools.authorized?(request)
        return json_response({ message: 'Not found.' }, 404) unless request.get?

        request.set_header('HTTP_X_REQUESTED_WITH', 'XMLHttpRequest')
        match = ENTRIES_PATH.match(request.path)
        id = match && match[1]

        return list_response(request) if match && id.nil?
        return json_response({ message: 'Not found.' }, 404) unless id&.match?(ID_PATTERN)

        entry = DevTools.store.fetch(id)
        entry ? json_response(entry) : json_response({ message: 'Not found.' }, 404)
      end

      def list_response(request)
        entries = DevTools.store.all
        component = request.params['component']
        include_types = comma_list(request.params['type'])
        exclude_types = comma_list(request.params['exclude'])

        entries = entries.select { |entry| entry.dig('__meta', 'component') == component } if component.present?
        if include_types.any?
          entries = entries.select { |entry| include_types.include?(entry.dig('__meta', 'requestType')) }
        end
        if exclude_types.any?
          entries = entries.reject { |entry| exclude_types.include?(entry.dig('__meta', 'requestType')) }
        end

        offset = [request.params['offset'].to_i, 0].max
        entries = entries.drop(offset)
        limit = request.params['limit']
        entries = entries.first([limit.to_i, 1].max) if limit.present?

        json_response(entries)
      end

      def comma_list(value)
        value.to_s.split(',').map(&:strip).reject(&:empty?)
      end

      def json_response(payload, status = 200)
        body = JSON.generate(payload)
        [
          status,
          {
            'Content-Type' => 'application/json; charset=utf-8',
            'Content-Length' => body.bytesize.to_s,
            'Cache-Control' => 'no-store',
            'X-Content-Type-Options' => 'nosniff',
          },
          [body]
        ]
      end

      def devtools_path?(path)
        path == '/_inertia/devtools/entries' || path.start_with?('/_inertia/devtools/entries/')
      end

      def initial_html_response?(request, status, headers)
        return false if request.headers['X-Inertia']
        return false unless status == 200
        return false unless request.get_header(PAGE_ENV_KEY).is_a?(Hash)

        content_type = response_header(headers, 'Content-Type').to_s.downcase
        content_type.include?('text/html')
      end

      def devtools_tag(id)
        %(<script data-inertia-devtools-id type="application/json">#{JSON.generate(id)}</script>)
      end

      def present_header(request, name)
        value = request.headers[name]
        value.is_a?(String) && !value.empty? ? value : nil
      end

      def prefetch?(request)
        [request.headers['Purpose'], request.headers['Sec-Purpose']].compact.any? do |value|
          value.downcase.split(/[;,]\s*/).include?('prefetch')
        end
      end

      def response_header(headers, name)
        pair = headers.find { |key, _value| key.to_s.casecmp?(name) }
        pair&.last
      end

      def delete_response_header(headers, name)
        key = headers.keys.find { |candidate| candidate.to_s.casecmp?(name) }
        headers.delete(key) if key
      end

      def delete_injected_body_headers(headers)
        %w[Content-Length ETag Last-Modified].each do |name|
          delete_response_header(headers, name)
        end
      end
    end

    class InjectingBody
      def initialize(body, tag)
        @body = body
        @tag = tag
      end

      def each
        content = +''
        @body.each { |chunk| content << chunk.to_s }

        index = content.downcase.rindex('</body>')
        index ? content.insert(index, @tag) : content << @tag
        yield content
      end

      def close
        return if @closed

        @closed = true
        @body.close if @body.respond_to?(:close)
      end
    end
  end
end
