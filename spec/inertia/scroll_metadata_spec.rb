# frozen_string_literal: true

RSpec.describe InertiaRails::ScrollMetadata do
  describe '.extract' do
    context 'with Kaminari adapter' do
      before do
        stub_const('Kaminari', Class.new)
        stub_const('Kaminari::PageScopeMethods', Module.new)
        allow(Kaminari).to receive(:config).and_return(double(param_name: 'page'))
      end

      let(:kaminari_metadata) do
        instance_double('KaminariPage').tap do |metadata|
          metadata.extend(Kaminari::PageScopeMethods)
          allow(metadata).to receive(:prev_page).and_return(1)
          allow(metadata).to receive(:next_page).and_return(3)
          allow(metadata).to receive(:current_page).and_return(2)
        end
      end

      it 'extracts metadata from Kaminari paginator' do
        result = described_class.extract(kaminari_metadata)

        expect(result).to eq(
          pageName: 'page',
          previousPage: 1,
          nextPage: 3,
          currentPage: 2
        )
      end

      it 'handles nil param_name in Kaminari config' do
        allow(Kaminari.config).to receive(:param_name).and_return(nil)

        result = described_class.extract(kaminari_metadata)

        expect(result).to eq(
          pageName: 'page',
          previousPage: 1,
          nextPage: 3,
          currentPage: 2
        )
      end

      it 'allows options to override metadata values' do
        result = described_class.extract(
          kaminari_metadata,
          page_name: 'custom_page',
          current_page: 5
        )

        expect(result).to eq(
          pageName: 'custom_page',
          previousPage: 1,
          nextPage: 3,
          currentPage: 5
        )
      end
    end

    context 'with Pagy adapter' do
      before do
        stub_const('Pagy', Class.new)
      end

      let(:pagy_metadata) do
        instance_double('Pagy').tap do |metadata|
          allow(metadata).to receive(:is_a?).and_return(false)
          allow(metadata).to receive(:is_a?).with(Pagy).and_return(true)
          allow(metadata).to receive(:vars).and_return({ page_param: :page })
          allow(metadata).to receive(:prev).and_return(1)
          allow(metadata).to receive(:next).and_return(3)
          allow(metadata).to receive(:page).and_return(2)
        end
      end

      it 'extracts metadata from Pagy paginator' do
        result = described_class.extract(pagy_metadata)

        expect(result).to eq(
          pageName: 'page',
          previousPage: 1,
          nextPage: 3,
          currentPage: 2
        )
      end

      it 'raises error when page_param is missing from vars' do
        allow(pagy_metadata).to receive(:vars).and_return({})

        expect do
          described_class.extract(pagy_metadata)
        end.to raise_error(KeyError)
      end

      it 'allows options to override metadata values' do
        result = described_class.extract(
          pagy_metadata,
          page_name: 'items_page',
          previous_page: 0
        )

        expect(result).to eq(
          pageName: 'items_page',
          previousPage: 0,
          nextPage: 3,
          currentPage: 2
        )
      end
    end

    context 'with Hash adapter' do
      let(:hash_metadata) do
        {
          page_name: 'items',
          previous_page: 1,
          next_page: 3,
          current_page: 2,
        }
      end

      it 'extracts metadata from hash' do
        result = described_class.extract(hash_metadata)

        expect(result).to eq(
          pageName: 'items',
          previousPage: 1,
          nextPage: 3,
          currentPage: 2
        )
      end

      it 'raises error when required keys are missing' do
        incomplete_hash = { page_name: 'items' }

        expect do
          described_class.extract(incomplete_hash)
        end.to raise_error(KeyError)
      end

      it 'allows options to override hash values' do
        result = described_class.extract(
          hash_metadata,
          page_name: 'overridden',
          next_page: 5
        )

        expect(result).to eq(
          pageName: 'overridden',
          previousPage: 1,
          nextPage: 5,
          currentPage: 2
        )
      end
    end

    context 'with unsupported metadata type' do
      it 'raises MissingMetadataAdapterError with no options provided' do
        unsupported_metadata = 'unsupported'

        expect do
          described_class.extract(unsupported_metadata)
        end.to raise_error(
          InertiaRails::ScrollMetadata::MissingMetadataAdapterError,
          'No ScrollMetadata adapter found for unsupported'
        )
      end

      it 'uses options as fallback when no adapter matches' do
        unsupported_metadata = 'unsupported'

        result = described_class.extract(
          unsupported_metadata,
          page_name: 'fallback',
          previous_page: nil,
          next_page: nil,
          current_page: 1
        )

        expect(result).to eq(
          pageName: 'fallback',
          previousPage: nil,
          nextPage: nil,
          currentPage: 1
        )
      end

      it 'raises error when insufficient options provided for unsupported type' do
        unsupported_metadata = 'unsupported'

        expect do
          described_class.extract(unsupported_metadata, page_name: 'fallback')
        end.to raise_error(
          InertiaRails::ScrollMetadata::MissingMetadataAdapterError,
          'No ScrollMetadata adapter found for unsupported'
        )
      end
    end

    context 'with nil metadata' do
      it 'uses options to create props when all required options provided' do
        result = described_class.extract(
          nil,
          page_name: 'nil_page',
          previous_page: nil,
          next_page: 2,
          current_page: 1
        )

        expect(result).to eq(
          pageName: 'nil_page',
          previousPage: nil,
          nextPage: 2,
          currentPage: 1
        )
      end

      it 'raises error when insufficient options provided for nil metadata' do
        expect do
          described_class.extract(nil, page_name: 'partial')
        end.to raise_error(
          InertiaRails::ScrollMetadata::MissingMetadataAdapterError,
          'No ScrollMetadata adapter found for '
        )
      end
    end
  end

  describe '.register_adapter' do
    after do
      # Reset adapters to original state
      described_class.adapters = [
        InertiaRails::ScrollMetadata::KaminariAdapter,
        InertiaRails::ScrollMetadata::PagyAdapter,
        InertiaRails::ScrollMetadata::HashAdapter
      ].map(&:new)
    end

    it 'registers custom adapter and gives it priority' do
      custom_adapter_class = Class.new do
        def match?(metadata)
          metadata == 'custom'
        end

        def call(_metadata, **_options)
          {
            page_name: 'custom_adapter',
            previous_page: nil,
            next_page: nil,
            current_page: 1,
          }
        end
      end

      described_class.register_adapter(custom_adapter_class)

      result = described_class.extract('custom')

      expect(result).to eq(
        pageName: 'custom_adapter',
        previousPage: nil,
        nextPage: nil,
        currentPage: 1
      )
    end

    it 'gives precedence to most recently registered adapters' do
      first_adapter = Class.new do
        def match?(metadata)
          metadata.is_a?(Hash)
        end

        def call(_metadata, **_options)
          {
            page_name: 'first_adapter',
            previous_page: nil,
            next_page: nil,
            current_page: 1,
          }
        end
      end

      second_adapter = Class.new do
        def match?(metadata)
          metadata.is_a?(Hash)
        end

        def call(_metadata, **_options)
          {
            page_name: 'second_adapter',
            previous_page: nil,
            next_page: nil,
            current_page: 1,
          }
        end
      end

      described_class.register_adapter(first_adapter)
      described_class.register_adapter(second_adapter)

      result = described_class.extract({})

      expect(result[:pageName]).to eq('second_adapter')
    end
  end

  describe InertiaRails::ScrollMetadata::Props do
    describe '#as_json' do
      it 'converts to proper JSON format' do
        props = described_class.new(
          page_name: 'items',
          previous_page: 1,
          next_page: 3,
          current_page: 2
        )

        result = props.as_json

        expect(result).to eq(
          pageName: 'items',
          previousPage: 1,
          nextPage: 3,
          currentPage: 2
        )
      end

      it 'ignores options parameter' do
        props = described_class.new(
          page_name: 'items',
          previous_page: 1,
          next_page: 3,
          current_page: 2
        )

        result = props.as_json({ some: 'options' })

        expect(result).to eq(
          pageName: 'items',
          previousPage: 1,
          nextPage: 3,
          currentPage: 2
        )
      end
    end
  end

  describe 'adapter precedence' do
    it 'tries adapters in registration order' do
      # Mock all adapters to match
      allow_any_instance_of(InertiaRails::ScrollMetadata::KaminariAdapter)
        .to receive(:match?).and_return(true)
      allow_any_instance_of(InertiaRails::ScrollMetadata::PagyAdapter)
        .to receive(:match?).and_return(true)
      allow_any_instance_of(InertiaRails::ScrollMetadata::HashAdapter)
        .to receive(:match?).and_return(true)

      # Mock calls to return identifiable results
      allow_any_instance_of(InertiaRails::ScrollMetadata::KaminariAdapter)
        .to receive(:call).and_return({
                                        page_name: 'kaminari',
                                        previous_page: nil,
                                        next_page: nil,
                                        current_page: 1,
                                      })

      result = described_class.extract('test')

      # Should use Kaminari adapter (first in the list)
      expect(result[:pageName]).to eq('kaminari')
    end
  end
end
