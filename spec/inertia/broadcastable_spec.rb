# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InertiaRails::Broadcastable do
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

  def build_child_class(parent, &block)
    Class.new(ActiveRecord::Base) do
      self.table_name = 'inertia_broadcast_test_records'

      # Anonymous classes have no model_name; broadcasts carry model names.
      def self.name
        'BroadcastTestRecord'
      end

      include InertiaRails::Broadcastable
      belongs_to :parent, class_name: parent.name, optional: true

      class_eval(&block)
    end
  end

  # --- broadcasts_to (lifecycle facts) ---

  describe '.broadcasts_to' do
    let(:child_class) do
      build_child_class(parent_class) do
        broadcasts_to ->(record) { [:test_stream, record.parent_id || :orphan] }
      end
    end

    it 'broadcasts a create fact on create' do
      parent = parent_class.create!(name: 'parent')

      expect(InertiaRails).to receive(:broadcast_change_to).with(
        [:test_stream, parent.id],
        hash_including(action: :create, record: an_instance_of(child_class))
      )
      child_class.create!(name: 'test', parent_id: parent.id)
    end

    it 'broadcasts an update fact on update' do
      parent = parent_class.create!(name: 'parent')
      record = child_class.create!(name: 'test', parent_id: parent.id)

      expect(InertiaRails).to receive(:broadcast_change_to).with(
        [:test_stream, parent.id],
        hash_including(action: :update)
      )
      record.update!(name: 'updated')
    end

    it 'broadcasts a destroy fact on destroy' do
      parent = parent_class.create!(name: 'parent')
      record = child_class.create!(name: 'test', parent_id: parent.id)

      expect(InertiaRails).to receive(:broadcast_change_to).with(
        [:test_stream, parent.id],
        hash_including(action: :destroy)
      )
      record.destroy!
    end

    it 'passes Current.live_request_id for self-exclusion' do
      parent = parent_class.create!(name: 'parent')
      allow(InertiaRails::Current).to receive(:live_request_id).and_return('req-A')

      expect(InertiaRails).to receive(:broadcast_change_to).with(
        anything,
        hash_including(request_id: 'req-A')
      )
      child_class.create!(name: 'test', parent_id: parent.id)
    end

    it 'never debounces facts — coalescing typed signals drops destroys' do
      parent = parent_class.create!(name: 'parent')

      expect(InertiaRails).to receive(:broadcast_change_to).exactly(3).times
      3.times { |i| child_class.create!(name: "test #{i}", parent_id: parent.id) }
    end

    context 'with on: option' do
      let(:child_class) do
        build_child_class(parent_class) do
          broadcasts_to ->(_record) { :test_stream }, on: :create
        end
      end

      it 'only broadcasts on specified events' do
        parent = parent_class.create!(name: 'parent')

        expect(InertiaRails).to receive(:broadcast_change_to).once
        record = child_class.create!(name: 'test', parent_id: parent.id)

        expect(InertiaRails).not_to receive(:broadcast_change_to)
        record.update!(name: 'updated')
      end
    end
  end

  # --- broadcasts_refreshes_to (reload) ---

  describe '.broadcasts_refreshes_to' do
    let(:child_class) do
      build_child_class(parent_class) do
        broadcasts_refreshes_to ->(record) { [:test_stream, record.parent_id || :orphan] }
      end
    end

    it 'sends reload on create, update, and destroy' do
      parent = parent_class.create!(name: 'parent')

      expect(InertiaRails).to receive(:broadcast_refresh_to).with([:test_stream, parent.id], anything).exactly(3).times

      record = child_class.create!(name: 'test', parent_id: parent.id)
      record.update!(name: 'updated')
      record.destroy!
    end

    context 'with on: option' do
      let(:child_class) do
        build_child_class(parent_class) do
          broadcasts_refreshes_to ->(_record) { :test_stream }, on: :create
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

  # --- hybrid coexistence with turbo-rails ---

  describe 'macro naming and Hotwire coexistence' do
    it 'defines the canonical inertia_-prefixed macros' do
      klass = build_child_class(parent_class) do
        inertia_broadcasts_to ->(_record) { :test_stream }
      end

      expect(InertiaRails).to receive(:broadcast_change_to)
      klass.create!(name: 'test')
    end

    it 'aliases the short names when no other library claimed them' do
      klass = build_child_class(parent_class) {}

      expect(klass).to respond_to(:broadcasts_to)
      expect(klass).to respond_to(:broadcasts_refreshes_to)
      expect(klass.method(:broadcasts_to).source_location)
        .to eq(klass.method(:inertia_broadcasts_to).source_location)
    end

    it 'leaves the short names alone when Turbo already defines them (hybrid apps)' do
      turbo_like = Module.new do
        def broadcasts_to(*, **)
          :turbo_owns_this
        end

        def broadcasts_refreshes_to(*, **)
          :turbo_owns_this
        end
      end

      klass = Class.new(ActiveRecord::Base) do
        self.table_name = 'inertia_broadcast_test_records'
        extend turbo_like
        include InertiaRails::Broadcastable
      end

      # Turbo's short names survive; ours are reachable via the prefix.
      expect(klass.broadcasts_to).to eq(:turbo_owns_this)
      expect(klass).to respond_to(:inertia_broadcasts_to)
      expect(klass).to respond_to(:inertia_broadcasts_refreshes_to)
    end
  end

  # --- debounce (refreshes only) ---

  describe '.broadcasts_refreshes_to with debounce' do
    around do |example|
      previous = InertiaRails::ThreadDebouncer.debouncer_class
      InertiaRails::ThreadDebouncer.debouncer_class = InertiaRails::Debouncer
      example.run
    ensure
      InertiaRails::ThreadDebouncer.debouncer_class = previous
    end

    let(:child_class) do
      build_child_class(parent_class) do
        broadcasts_refreshes_to ->(_record) { :test_stream }, debounce: 0.1
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

      expect(InertiaRails).to receive(:broadcast_refresh_to).with(:test_stream, hash_including(request_id: 'req-A')).once
      expect(InertiaRails).to receive(:broadcast_refresh_to).with(:test_stream, hash_including(request_id: 'req-B')).once

      allow(InertiaRails::Current).to receive(:live_request_id).and_return('req-A')
      child_class.create!(name: 'from-A', parent_id: parent.id)

      allow(InertiaRails::Current).to receive(:live_request_id).and_return('req-B')
      child_class.create!(name: 'from-B', parent_id: parent.id)

      # Wait for both distinct debouncer buckets to fire
      %w[req-A req-B].each do |req_id|
        key = "inertia_live_debounce:#{InertiaRails::StreamName.stream_name_from([:test_stream, req_id])}"
        Thread.current[key]&.wait
      end
    end
  end

  # --- suppression (per-class, works for both) ---

  describe '.suppressing_inertia_broadcasts' do
    let(:child_class) do
      build_child_class(parent_class) do
        broadcasts_to ->(record) { [:test_stream, record.parent_id || :orphan] }
      end
    end

    it 'suppresses broadcasts within the block' do
      parent = parent_class.create!(name: 'parent')

      expect(InertiaRails).not_to receive(:broadcast_change_to)
      child_class.suppressing_inertia_broadcasts do
        child_class.create!(name: 'suppressed', parent_id: parent.id)
      end
    end

    it 'resumes broadcasts after the block' do
      parent = parent_class.create!(name: 'parent')

      child_class.suppressing_inertia_broadcasts do
        child_class.create!(name: 'suppressed', parent_id: parent.id)
      end

      expect(InertiaRails).to receive(:broadcast_change_to)
      child_class.create!(name: 'not suppressed', parent_id: parent.id)
    end

    it 'is nestable' do
      parent = parent_class.create!(name: 'parent')

      expect(InertiaRails).not_to receive(:broadcast_change_to)
      child_class.suppressing_inertia_broadcasts do
        child_class.suppressing_inertia_broadcasts do
          child_class.create!(name: 'inner', parent_id: parent.id)
        end
        child_class.create!(name: 'outer', parent_id: parent.id)
      end
    end

    it 'is scoped to the class — suppressing one model does not silence another' do
      parent = parent_class.create!(name: 'parent')

      other_class = build_child_class(parent_class) do
        broadcasts_to ->(_record) { :other_stream }
      end

      expect(InertiaRails).to receive(:broadcast_change_to).with(:other_stream, hash_including(action: :create))

      child_class.suppressing_inertia_broadcasts do
        # child_class is silenced, but other_class must still broadcast
        child_class.create!(name: 'silent', parent_id: parent.id)
        other_class.create!(name: 'heard', parent_id: parent.id)
      end
    end
  end
end
