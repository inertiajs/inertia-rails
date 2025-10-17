# frozen_string_literal: true

RSpec.describe InertiaRails::ScrollProp do
  it_behaves_like 'base prop'

  describe '#metadata' do
    it 'resolves metadata from Pagy paginator' do
      collection = Array.new(100) { |i| "item#{i}" }
      pagy, = Pagy.new(count: collection.size, page: 1, items: 20)

      prop = described_class.new(metadata: pagy) { collection }
      metadata = prop.metadata

      expect(metadata).to eq(
        pageName: 'page',
        previousPage: nil,
        nextPage: 2,
        currentPage: 1
      )
    end

    it 'resolves metadata from Kaminari paginator' do
      collection = Array.new(100) { |i| "item#{i}" }
      collection = Kaminari.paginate_array(collection).page(1).per(20)

      prop = described_class.new(metadata: collection) { collection }
      metadata = prop.metadata

      another_prop = described_class.new(metadata: collection, page_name: 'another_pagination') { collection }
      another_metadata = another_prop.metadata

      expect(metadata).to eq(
        pageName: 'page',
        previousPage: nil,
        nextPage: 2,
        currentPage: 1
      )
      expect(another_metadata).to eq(
        pageName: 'another_pagination',
        previousPage: nil,
        nextPage: 2,
        currentPage: 1
      )
    end

    it 'resolves custom metadata from provider hash' do
      metadata = {
        page_name: 'custom_page',
        previous_page: 1,
        next_page: 3,
        current_page: 2,
      }

      prop = described_class.new(metadata: metadata) { %w[item1 item2] }
      metadata = prop.metadata

      expect(metadata).to eq(
        pageName: 'custom_page',
        previousPage: 1,
        nextPage: 3,
        currentPage: 2
      )
    end
  end

  describe '#configure_merge_intent' do
    let(:headers) { {} }
    let(:controller) do
      controller = double('Controller')
      request = double('Request')

      allow(controller).to receive(:request).and_return(request)
      allow(request).to receive(:headers).and_return(headers)
      controller
    end

    it 'defaults to appending when no header is present' do
      prop = described_class.new(wrapper: 'data') { %w[item1 item2] }
      prop.call(controller)

      expect(prop.appends_at_paths).to include('data')
      expect(prop.prepends_at_paths).to be_empty
    end

    context 'when merge intent header is "append"' do
      let(:headers) { { 'X-Inertia-Infinite-Scroll-Merge-Intent' => 'append' } }

      it 'appends' do
        prop = described_class.new(wrapper: 'data') { %w[item1 item2] }
        prop.call(controller)

        expect(prop.appends_at_paths).to include('data')
        expect(prop.prepends_at_paths).to be_empty
      end
    end

    context 'when merge intent header is "prepend"' do
      let(:headers) { { 'X-Inertia-Infinite-Scroll-Merge-Intent' => 'prepend' } }

      it 'prepends at root' do
        prop = described_class.new { %w[item1 item2] }
        prop.call(controller)

        expect(prop.prepends_at_paths).to be_empty
        expect(prop.appends_at_paths).to be_empty
        expect(prop.appends_at_root?).to be false
        expect(prop.prepends_at_root?).to be true
      end
    end

    context 'with custom wrapper key' do
      let(:headers) { { 'X-Inertia-Infinite-Scroll-Merge-Intent' => 'prepend' } }

      it 'prepends to the wrapper key' do
        prop = described_class.new(wrapper: 'items') { %w[item1 item2] }
        prop.call(controller)

        expect(prop.prepends_at_paths).to include('items')
        expect(prop.appends_at_paths).to be_empty
        expect(prop.appends_at_root?).to be false
        expect(prop.prepends_at_root?).to be false
      end
    end
  end

  describe '#merge?' do
    it 'always returns true' do
      prop = described_class.new { %w[item1 item2] }
      expect(prop.merge?).to be true
    end
  end

  describe 'edge cases' do
    let(:headers) { {} }
    let(:controller) do
      controller = double('Controller')
      request = double('Request')

      allow(controller).to receive(:request).and_return(request)
      allow(request).to receive(:headers).and_return(headers)
      controller
    end

    context 'with nil wrapper handling' do
      it 'does not configure merge intent when wrapper is nil' do
        prop = described_class.new(wrapper: nil) { %w[item1 item2] }
        prop.call(controller)

        expect(prop.appends_at_paths).to be_empty
        expect(prop.prepends_at_paths).to be_empty
      end
    end

    context 'with invalid metadata types' do
      it 'raises MissingMetadataAdapterError for unsupported metadata' do
        prop = described_class.new(metadata: 'unsupported_type') { %w[item1 item2] }

        expect do
          prop.metadata
        end.to raise_error(
          InertiaRails::ScrollMetadata::MissingMetadataAdapterError,
          'No ScrollMetadata adapter found for unsupported_type'
        )
      end

      it 'raises MissingMetadataAdapterError for custom objects' do
        custom_object = Class.new.new
        prop = described_class.new(metadata: custom_object) { %w[item1 item2] }

        expect do
          prop.metadata
        end.to raise_error(
          InertiaRails::ScrollMetadata::MissingMetadataAdapterError
        )
      end

      it 'uses options as fallback when metadata is unsupported' do
        prop = described_class.new(
          metadata: 'unsupported',
          page_name: 'fallback',
          previous_page: nil,
          next_page: 2,
          current_page: 1
        ) { %w[item1 item2] }

        result = prop.metadata

        expect(result).to eq(
          pageName: 'fallback',
          previousPage: nil,
          nextPage: 2,
          currentPage: 1
        )
      end
    end

    context 'with malformed headers' do
      it 'defaults to append with unexpected header value' do
        headers = { 'X-Inertia-Infinite-Scroll-Merge-Intent' => 'invalid_value' }
        allow(controller.request).to receive(:headers).and_return(headers)

        prop = described_class.new(wrapper: 'data') { %w[item1 item2] }
        prop.call(controller)

        expect(prop.appends_at_paths).to include('data')
        expect(prop.prepends_at_paths).to be_empty
      end

      it 'defaults to append with empty header value' do
        headers = { 'X-Inertia-Infinite-Scroll-Merge-Intent' => '' }
        allow(controller.request).to receive(:headers).and_return(headers)

        prop = described_class.new(wrapper: 'data') { %w[item1 item2] }
        prop.call(controller)

        expect(prop.appends_at_paths).to include('data')
        expect(prop.prepends_at_paths).to be_empty
      end

      it 'defaults to append with nil header value' do
        headers = { 'X-Inertia-Infinite-Scroll-Merge-Intent' => nil }
        allow(controller.request).to receive(:headers).and_return(headers)

        prop = described_class.new(wrapper: 'data') { %w[item1 item2] }
        prop.call(controller)

        expect(prop.appends_at_paths).to include('data')
        expect(prop.prepends_at_paths).to be_empty
      end

      it 'handles case sensitivity correctly' do
        headers = { 'X-Inertia-Infinite-Scroll-Merge-Intent' => 'PREPEND' }
        allow(controller.request).to receive(:headers).and_return(headers)

        prop = described_class.new(wrapper: 'data') { %w[item1 item2] }
        prop.call(controller)

        expect(prop.appends_at_paths).to include('data')
        expect(prop.prepends_at_paths).to be_empty
      end

      it 'handles prepend with correct case' do
        headers = { 'X-Inertia-Infinite-Scroll-Merge-Intent' => 'prepend' }
        allow(controller.request).to receive(:headers).and_return(headers)

        prop = described_class.new(wrapper: 'data') { %w[item1 item2] }
        prop.call(controller)

        expect(prop.prepends_at_paths).to include('data')
        expect(prop.appends_at_paths).to be_empty
      end
    end

    context 'with metadata options precedence' do
      let(:hash_metadata) do
        {
          page_name: 'original',
          previous_page: 1,
          next_page: 3,
          current_page: 2,
        }
      end

      it 'allows page_name override' do
        prop = described_class.new(
          metadata: hash_metadata,
          page_name: 'overridden'
        ) { %w[item1 item2] }

        result = prop.metadata

        expect(result[:pageName]).to eq('overridden')
        expect(result[:currentPage]).to eq(2)
      end

      it 'allows multiple options override' do
        prop = described_class.new(
          metadata: hash_metadata,
          page_name: 'custom_page',
          current_page: 5,
          next_page: 6
        ) { %w[item1 item2] }

        result = prop.metadata

        expect(result).to eq(
          pageName: 'custom_page',
          previousPage: 1,
          nextPage: 6,
          currentPage: 5
        )
      end

      it 'preserves original metadata when no options provided' do
        prop = described_class.new(metadata: hash_metadata) { %w[item1 item2] }

        result = prop.metadata

        expect(result).to eq(
          pageName: 'original',
          previousPage: 1,
          nextPage: 3,
          currentPage: 2
        )
      end
    end

    context 'without metadata' do
      it 'handles nil metadata with options' do
        prop = described_class.new(
          metadata: nil,
          page_name: 'no_metadata',
          previous_page: nil,
          next_page: 2,
          current_page: 1
        ) { %w[item1 item2] }

        result = prop.metadata

        expect(result).to eq(
          pageName: 'no_metadata',
          previousPage: nil,
          nextPage: 2,
          currentPage: 1
        )
      end

      it 'raises error when metadata is nil and insufficient options' do
        prop = described_class.new(
          metadata: nil,
          page_name: 'incomplete'
        ) { %w[item1 item2] }

        expect do
          prop.metadata
        end.to raise_error(
          InertiaRails::ScrollMetadata::MissingMetadataAdapterError,
          'No ScrollMetadata adapter found for '
        )
      end
    end
  end
end
