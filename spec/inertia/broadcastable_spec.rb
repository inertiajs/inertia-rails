# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InertiaRails::Broadcastable do
  let(:verifier) { ActiveSupport::MessageVerifier.new('test-key', digest: 'SHA256', serializer: JSON) }

  before do
    allow(InertiaRails).to receive(:signed_stream_verifier).and_return(verifier)
  end

  before(:all) do
    ActiveRecord::Schema.define do
      drop_table :inertia_broadcast_test_records, if_exists: true
      drop_table :inertia_broadcast_test_parents, if_exists: true

      create_table :inertia_broadcast_test_parents, force: true do |t|
        t.string :name
        t.timestamps
      end

      create_table :inertia_broadcast_test_records, force: true do |t|
        t.string :name
        t.integer :parent_id
        t.timestamps
      end
    end
  end

  let(:parent_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'inertia_broadcast_test_parents'
    end
  end

  # --- broadcasts_to (surgical) ---

  describe '.broadcasts_to (surgical)' do
    let(:child_class) do
      parent = parent_class
      Class.new(ActiveRecord::Base) do
        self.table_name = 'inertia_broadcast_test_records'
        include InertiaRails::Broadcastable
        belongs_to :parent, class_name: parent.name, optional: true

        broadcasts_to ->(record) { [:test_stream, record.parent_id || :orphan] }
      end
    end

    it 'sends create action on create' do
      parent = parent_class.create!(name: 'parent')

      expect(InertiaRails).to receive(:broadcast_action_to).with(
        [:test_stream, parent.id],
        hash_including(action: :append)
      )
      child_class.create!(name: 'test', parent_id: parent.id)
    end

    it 'sends replace action on update' do
      parent = parent_class.create!(name: 'parent')
      record = child_class.create!(name: 'test', parent_id: parent.id)

      expect(InertiaRails).to receive(:broadcast_action_to).with(
        [:test_stream, parent.id],
        hash_including(action: :replace)
      )
      record.update!(name: 'updated')
    end

    it 'sends remove action on destroy' do
      parent = parent_class.create!(name: 'parent')
      record = child_class.create!(name: 'test', parent_id: parent.id)

      expect(InertiaRails).to receive(:broadcast_action_to).with(
        [:test_stream, parent.id],
        hash_including(action: :remove)
      )
      record.destroy!
    end

    context 'with inserts_by: :prepend' do
      let(:child_class) do
        parent = parent_class
        Class.new(ActiveRecord::Base) do
          self.table_name = 'inertia_broadcast_test_records'
          include InertiaRails::Broadcastable
          belongs_to :parent, class_name: parent.name, optional: true

          broadcasts_to ->(record) { :test_stream }, inserts_by: :prepend
        end
      end

      it 'sends prepend action on create' do
        parent = parent_class.create!(name: 'parent')

        expect(InertiaRails).to receive(:broadcast_action_to).with(
          :test_stream,
          hash_including(action: :prepend)
        )
        child_class.create!(name: 'test', parent_id: parent.id)
      end
    end

    context 'with serializer: option (lambda)' do
      let(:child_class) do
        parent = parent_class
        Class.new(ActiveRecord::Base) do
          self.table_name = 'inertia_broadcast_test_records'
          include InertiaRails::Broadcastable
          belongs_to :parent, class_name: parent.name, optional: true

          broadcasts_to(->(record) { :test_stream },
            serializer: ->(record) { { id: record.id, custom: true } })
        end
      end

      it 'passes the serializer option through to broadcast_action_to' do
        parent = parent_class.create!(name: 'parent')

        expect(InertiaRails).to receive(:broadcast_action_to).with(
          :test_stream,
          hash_including(serializer: an_instance_of(Proc))
        )
        child_class.create!(name: 'test', parent_id: parent.id)
      end
    end

    context 'with on: option' do
      let(:child_class) do
        parent = parent_class
        Class.new(ActiveRecord::Base) do
          self.table_name = 'inertia_broadcast_test_records'
          include InertiaRails::Broadcastable
          belongs_to :parent, class_name: parent.name, optional: true

          broadcasts_to ->(record) { :test_stream }, on: :create
        end
      end

      it 'only broadcasts on specified events' do
        parent = parent_class.create!(name: 'parent')

        expect(InertiaRails).to receive(:broadcast_action_to).once
        record = child_class.create!(name: 'test', parent_id: parent.id)

        expect(InertiaRails).not_to receive(:broadcast_action_to)
        record.update!(name: 'updated')
      end
    end
  end

  # --- broadcasts_refreshes_to (reload) ---

  describe '.broadcasts_refreshes_to (reload)' do
    let(:child_class) do
      parent = parent_class
      Class.new(ActiveRecord::Base) do
        self.table_name = 'inertia_broadcast_test_records'
        include InertiaRails::Broadcastable
        belongs_to :parent, class_name: parent.name, optional: true

        broadcasts_refreshes_to ->(record) { [:test_stream, record.parent_id || :orphan] }
      end
    end

    it 'sends reload on create' do
      parent = parent_class.create!(name: 'parent')

      expect(InertiaRails).to receive(:broadcast_refresh_to).with([:test_stream, parent.id], anything)
      child_class.create!(name: 'test', parent_id: parent.id)
    end

    it 'sends reload on update' do
      parent = parent_class.create!(name: 'parent')
      record = child_class.create!(name: 'test', parent_id: parent.id)

      expect(InertiaRails).to receive(:broadcast_refresh_to).with([:test_stream, parent.id], anything)
      record.update!(name: 'updated')
    end

    it 'sends reload on destroy' do
      parent = parent_class.create!(name: 'parent')
      record = child_class.create!(name: 'test', parent_id: parent.id)

      expect(InertiaRails).to receive(:broadcast_refresh_to).with([:test_stream, parent.id], anything)
      record.destroy!
    end

    context 'with on: option' do
      let(:child_class) do
        parent = parent_class
        Class.new(ActiveRecord::Base) do
          self.table_name = 'inertia_broadcast_test_records'
          include InertiaRails::Broadcastable
          belongs_to :parent, class_name: parent.name, optional: true

          broadcasts_refreshes_to ->(record) { :test_stream }, on: :create
        end
      end

      it 'only broadcasts on specified events' do
        parent = parent_class.create!(name: 'parent')

        expect(InertiaRails).to receive(:broadcast_refresh_to).once
        record = child_class.create!(name: 'test', parent_id: parent.id)

        expect(InertiaRails).not_to receive(:broadcast_refresh_to)
        record.update!(name: 'updated')
      end
    end
  end

  # --- debounce ---

  describe '.broadcasts_refreshes_to with debounce' do
    around do |example|
      previous = InertiaRails::ThreadDebouncer.debouncer_class
      InertiaRails::ThreadDebouncer.debouncer_class = InertiaRails::Debouncer
      example.run
    ensure
      InertiaRails::ThreadDebouncer.debouncer_class = previous
    end

    let(:child_class) do
      parent = parent_class
      Class.new(ActiveRecord::Base) do
        self.table_name = 'inertia_broadcast_test_records'
        include InertiaRails::Broadcastable
        belongs_to :parent, class_name: parent.name, optional: true

        broadcasts_refreshes_to ->(record) { :test_stream }, debounce: 0.1
      end
    end

    it 'coalesces rapid creates into one broadcast' do
      parent = parent_class.create!(name: 'parent')

      expect(InertiaRails).to receive(:broadcast_refresh_to).with(:test_stream, anything).once

      3.times { |i| child_class.create!(name: "test #{i}", parent_id: parent.id) }

      # Wait for the real (non-immediate) debouncer to fire
      key = "inertia_live_debounce:#{InertiaRails::StreamName.stream_name_from([:test_stream])}"
      Thread.current[key]&.wait
    end

    it 'keys debouncers per request_id so concurrent requests do not coalesce' do
      parent = parent_class.create!(name: 'parent')

      # Two requests, two distinct request_ids — we expect two broadcasts.
      expect(InertiaRails).to receive(:broadcast_refresh_to).with(:test_stream, hash_including(request_id: 'req-A')).once
      expect(InertiaRails).to receive(:broadcast_refresh_to).with(:test_stream, hash_including(request_id: 'req-B')).once

      InertiaRails::Current.live_request_id = 'req-A'
      child_class.create!(name: 'from-A', parent_id: parent.id)

      InertiaRails::Current.live_request_id = 'req-B'
      child_class.create!(name: 'from-B', parent_id: parent.id)

      # Wait for both distinct debouncer buckets to fire
      %w[req-A req-B].each do |req_id|
        key = "inertia_live_debounce:#{InertiaRails::StreamName.stream_name_from([:test_stream, req_id])}"
        Thread.current[key]&.wait
      end
    ensure
      InertiaRails::Current.live_request_id = nil
    end
  end

  # --- suppression (per-class, works for both) ---

  describe '.suppressing_inertia_broadcasts' do
    let(:child_class) do
      parent = parent_class
      Class.new(ActiveRecord::Base) do
        self.table_name = 'inertia_broadcast_test_records'
        include InertiaRails::Broadcastable
        belongs_to :parent, class_name: parent.name, optional: true

        broadcasts_to ->(record) { [:test_stream, record.parent_id || :orphan] }
      end
    end

    it 'suppresses broadcasts within the block' do
      parent = parent_class.create!(name: 'parent')

      expect(InertiaRails).not_to receive(:broadcast_action_to)
      child_class.suppressing_inertia_broadcasts do
        child_class.create!(name: 'suppressed', parent_id: parent.id)
      end
    end

    it 'resumes broadcasts after the block' do
      parent = parent_class.create!(name: 'parent')

      child_class.suppressing_inertia_broadcasts do
        child_class.create!(name: 'suppressed', parent_id: parent.id)
      end

      expect(InertiaRails).to receive(:broadcast_action_to)
      child_class.create!(name: 'not suppressed', parent_id: parent.id)
    end

    it 'is nestable' do
      parent = parent_class.create!(name: 'parent')

      expect(InertiaRails).not_to receive(:broadcast_action_to)
      child_class.suppressing_inertia_broadcasts do
        child_class.suppressing_inertia_broadcasts do
          child_class.create!(name: 'inner', parent_id: parent.id)
        end
        child_class.create!(name: 'outer', parent_id: parent.id)
      end
    end

    it 'is scoped to the class — suppressing one model does not silence another' do
      parent = parent_class.create!(name: 'parent')
      parent_klass = parent_class

      other_class = Class.new(ActiveRecord::Base) do
        self.table_name = 'inertia_broadcast_test_records'
        include InertiaRails::Broadcastable
        belongs_to :parent, class_name: parent_klass.name, optional: true

        broadcasts_to ->(_record) { :other_stream }
      end

      expect(InertiaRails).to receive(:broadcast_action_to).with(:other_stream, hash_including(action: :append))

      child_class.suppressing_inertia_broadcasts do
        # child_class is silenced, but other_class must still broadcast
        child_class.create!(name: 'silent', parent_id: parent.id)
        other_class.create!(name: 'heard', parent_id: parent.id)
      end
    end
  end
end
