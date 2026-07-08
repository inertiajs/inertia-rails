# frozen_string_literal: true

module InertiaRails
  module Testing
    # Emits the wire-contract fixture shared with @inertia-rails/core
    # (packages/core/__tests__/contracts/v1.json in inertia-rails/client).
    # Everything the server owns — message shapes, page metadata, channel and
    # header names, protocol version — is generated from the REAL code paths;
    # only the expected client reactions are declared. The client repo's CI
    # regenerates this file from the gem and diffs: byte drift fails the build
    # before it fails in production.
    module LiveContracts
      PLACEHOLDER_TOKENS = {
        'token_a' => 'SIGNED_TOKEN_A',
        'token_b' => 'SIGNED_TOKEN_B',
      }.freeze

      class << self
        def to_json_file
          "#{JSON.pretty_generate(generate)}\n"
        end

        def generate
          {
            protocol: Broadcast::PROTOCOL,
            channel: InertiaRails::StreamsChannel.name,
            header: Broadcast::REQUEST_ID_HEADER,
            request_id_format: js_request_id_format,
            pages: pages,
            signals: signals,
          }
        end

        private

        # Current::LIVE_REQUEST_ID_FORMAT with anchors translated for JS
        # RegExp. Ids the client generates must satisfy this or the server
        # drops them and self-exclusion silently stops working.
        def js_request_id_format
          Current::LIVE_REQUEST_ID_FORMAT.source.sub('\A', '^').sub('\z', '$')
        end

        def pages
          with_placeholder_verifier do
            {
              full: page(
                tasks: InertiaRails.live(:token_a) { [] },
                task_count: InertiaRails.live(:token_a) { 0 }
              ),
              two_streams: page(
                tasks: InertiaRails.live(:token_a) { [] },
                notifications: InertiaRails.live(:token_b) { [] }
              ),
              with_destroy_filter: page(
                tasks: InertiaRails.live(:token_a, on_destroy: 'Task') { [] },
                task_count: InertiaRails.live(:token_a) { 0 }
              ),
            }
          end
        end

        # Runs the real PropsResolver so the metadata shape (streams grouping,
        # filters, protocol) can never drift from what renders in production.
        def page(props)
          evaluator = Object.new
          evaluator.define_singleton_method(:call) { |prop| prop.respond_to?(:call) ? prop.call(self) : prop }
          _resolved, metadata = PropsResolver.new(props, evaluator: evaluator).resolve
          { url: '/tasks', rails: metadata[:rails] }
        end

        def signals
          record = Struct.new(:id, :model_name).new(2, Struct.new(:name).new('Task'))
          create_record = Struct.new(:id, :model_name).new(42, Struct.new(:name).new('Task'))

          [
            {
              name: 'refresh',
              page: 'full',
              message: capture { Broadcast.refresh_to(:s, request_id: 'req-other') },
              expect: { reload: { only: %w[tasks task_count] } },
            },
            {
              name: 'refresh_without_request_id',
              page: 'full',
              message: capture { Broadcast.refresh_to(:s) },
              expect: { reload: { only: %w[tasks task_count] } },
            },
            {
              name: 'create',
              page: 'full',
              message: capture do
                Broadcast.change_to(:s, record: create_record, action: :create, request_id: 'req-other')
              end,
              expect: { reload: { only: %w[tasks task_count] } },
            },
            {
              name: 'update',
              page: 'full',
              message: capture { Broadcast.change_to(:s, record: record, action: :update, request_id: 'req-other') },
              expect: { reload: { only: %w[tasks task_count] } },
            },
            {
              name: 'destroy_without_filter',
              page: 'full',
              message: capture { Broadcast.change_to(:s, record: record, action: :destroy, request_id: 'req-other') },
              expect: { reload: { only: %w[tasks task_count] } },
            },
            {
              name: 'destroy_with_filter',
              page: 'with_destroy_filter',
              message: capture { Broadcast.change_to(:s, record: record, action: :destroy, request_id: 'req-other') },
              expect: {
                filtered: { prop: 'tasks', removedKey: '2' },
                reload: { only: %w[task_count] },
              },
            },
            {
              name: 'destroy_filter_model_mismatch',
              page: 'with_destroy_filter',
              message: capture do
                other = Struct.new(:id, :model_name).new(2, Struct.new(:name).new('Comment'))
                Broadcast.change_to(:s, record: other, action: :destroy, request_id: 'req-other')
              end,
              expect: { reload: { only: %w[tasks task_count] } },
            },
            {
              name: 'self_excluded',
              page: 'full',
              message: capture { Broadcast.refresh_to(:s, request_id: 'req-own') },
              expect: { nothing: true },
            },
            {
              name: 'unknown_future_type',
              page: 'full',
              message: { type: 'compact_v9', request_id: 'req-other' },
              expect: { reload: { only: %w[tasks task_count] } },
            }
          ]
        end

        # Captures the exact hash the gem hands to ActionCable.
        def capture(&block)
          captured = nil
          fake_server = Object.new
          fake_server.define_singleton_method(:broadcast) { |_stream, message| captured = message }

          swapping_ivar(ActionCable, :@server, fake_server, &block)
          captured
        end

        def with_placeholder_verifier(&block)
          fake = Object.new
          fake.define_singleton_method(:generate) do |name|
            PLACEHOLDER_TOKENS.fetch(name) { raise ArgumentError, "no placeholder for stream #{name.inspect}" }
          end

          swapping_ivar(InertiaRails, :@signed_stream_verifier, fake, &block)
        end

        def swapping_ivar(owner, ivar, replacement)
          original = owner.instance_variable_get(ivar)
          owner.instance_variable_set(ivar, replacement)
          yield
        ensure
          owner.instance_variable_set(ivar, original)
        end
      end
    end
  end
end
