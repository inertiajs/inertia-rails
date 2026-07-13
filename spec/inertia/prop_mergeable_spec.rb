# frozen_string_literal: true

RSpec.describe InertiaRails::PropMergeable do
  let(:test_class) do
    Class.new(InertiaRails::BaseProp) do
      prepend InertiaRails::PropMergeable

      def initialize(**_props, &block)
        super(&block)
      end
    end
  end

  describe '#initialize' do
    it 'raises ArgumentError when both deep_merge and merge are true' do
      expect do
        test_class.new(deep_merge: true, merge: true)
      end.to raise_error(ArgumentError, 'Cannot set both `deep_merge` and `merge` to true')
    end

    context 'default values' do
      it 'sets default values correctly' do
        instance = test_class.new

        expect(instance.deep_merge?).to be false
        expect(instance.merge?).to be false
        expect(instance.match_on).to be_nil
        expect(instance.appends_at_paths).to eq([])
        expect(instance.prepends_at_paths).to eq([])
      end

      it 'sets merge to true when deep_merge is true' do
        instance = test_class.new(deep_merge: true)

        expect(instance.deep_merge?).to be true
        expect(instance.merge?).to be true
      end
    end

    context 'match_on handling' do
      it 'converts string match_on to array' do
        instance = test_class.new(match_on: 'id')

        expect(instance.match_on).to eq(['id'])
      end

      it 'keeps array match_on as array' do
        instance = test_class.new(match_on: %w[id slug])

        expect(instance.match_on).to eq(%w[id slug])
      end

      it 'handles nil match_on' do
        instance = test_class.new(match_on: nil)

        expect(instance.match_on).to be_nil
      end
    end

    context 'append handling' do
      context 'with boolean values' do
        it 'sets append flag to true' do
          instance = test_class.new(merge: true, append: true)

          expect(instance.appends_at_root?).to be true
          expect(instance.prepends_at_root?).to be false
        end

        it 'sets append flag to false when merge is false' do
          instance = test_class.new(merge: false, append: true)

          expect(instance.appends_at_root?).to be false
          expect(instance.prepends_at_root?).to be false
        end

        it 'sets append flag to false' do
          instance = test_class.new(merge: true, append: false)

          expect(instance.appends_at_root?).to be false
          expect(instance.prepends_at_root?).to be true
        end
      end

      context 'with string paths' do
        it 'adds string path to appends_at_paths' do
          instance = test_class.new(merge: true, append: 'items')

          expect(instance.appends_at_paths).to include('items')
          expect(instance.prepends_at_paths).to be_empty
        end

        it 'adds match_on when provided' do
          instance = test_class.new(merge: true, append: { 'items' => nil, 'products' => 'id' })

          expect(instance.match_on).to match_array(['products.id'])
        end
      end

      context 'with array paths' do
        it 'adds all paths from array to appends_at_paths' do
          instance = test_class.new(merge: true, append: %w[items products])

          expect(instance.appends_at_paths).to include('items', 'products')
          expect(instance.prepends_at_paths).to be_empty
        end
      end

      context 'with hash paths' do
        it 'adds keys as paths and creates match_on patterns' do
          instance = test_class.new(merge: true, append: { items: 'id', products: 'slug' })

          expect(instance.appends_at_paths).to include('items', 'products')
          expect(instance.match_on).to include('items.id', 'products.slug')
        end

        it 'handles hash with nil values' do
          instance = test_class.new(merge: true, append: { items: nil, products: 'slug' })

          expect(instance.appends_at_paths).to include('items', 'products')
          expect(instance.match_on).to include('products.slug')
          expect(instance.match_on).not_to include('items.')
        end

        it 'initializes match_on when not previously set' do
          instance = test_class.new
          instance.send(:append, { items: 'id' })

          expect(instance.match_on).to include('items.id')
        end
      end
    end

    context 'prepend handling' do
      context 'with boolean values' do
        it 'sets append flag to false when prepend is true' do
          instance = test_class.new(merge: true, prepend: true)

          expect(instance.appends_at_root?).to be false
          expect(instance.prepends_at_root?).to be true
        end

        it 'sets append flag to true when prepend is false' do
          instance = test_class.new(merge: true, prepend: false)

          expect(instance.appends_at_root?).to be true
          expect(instance.prepends_at_root?).to be false
        end
      end

      context 'with string paths' do
        it 'adds string path to prepends_at_paths' do
          instance = test_class.new(merge: true, prepend: 'items')

          expect(instance.prepends_at_paths).to include('items')
          expect(instance.appends_at_paths).to be_empty
        end

        it 'adds match_on when provided' do
          instance = test_class.new(merge: true, prepend: 'items')
          instance.send(:prepend, 'products', match_on: 'id')

          expect(instance.match_on).to include('products.id')
        end
      end

      context 'with array paths' do
        it 'adds all paths from array to prepends_at_paths' do
          instance = test_class.new(merge: true, prepend: %w[items products])

          expect(instance.prepends_at_paths).to include('items', 'products')
          expect(instance.appends_at_paths).to be_empty
        end
      end

      context 'with hash paths' do
        it 'adds keys as paths and creates match_on patterns' do
          instance = test_class.new(merge: true, prepend: { items: 'id', products: 'slug' })

          expect(instance.prepends_at_paths).to include('items', 'products')
          expect(instance.match_on).to include('items.id', 'products.slug')
        end

        it 'handles hash with nil values' do
          instance = test_class.new(merge: true, prepend: { items: nil, products: 'slug' })

          expect(instance.prepends_at_paths).to include('items', 'products')
          expect(instance.match_on).to include('products.slug')
          expect(instance.match_on).not_to include('items.')
        end
      end
    end
  end
  describe 'state query methods' do
    describe '#merges_at_root?' do
      it 'returns false when merge is false' do
        instance = test_class.new(merge: false, append: 'items')

        expect(instance.merges_at_root?).to be false
      end

      it 'returns true when no paths are configured and merge is true' do
        instance = test_class.new(merge: true)

        expect(instance.merges_at_root?).to be true
      end

      it 'returns false when append paths are configured' do
        instance = test_class.new(merge: true, append: 'items')

        expect(instance.merges_at_root?).to be false
      end

      it 'returns false when prepend paths are configured' do
        instance = test_class.new(merge: true, prepend: 'items')

        expect(instance.merges_at_root?).to be false
      end

      it 'returns false when both append and prepend paths are configured' do
        instance = test_class.new(merge: true, append: 'items', prepend: 'products')

        expect(instance.merges_at_root?).to be false
      end
    end

    describe '#appends_at_root?' do
      it 'returns false when merge? is false' do
        instance = test_class.new(merge: false)

        expect(instance.appends_at_root?).to be false
      end

      it 'returns false when merge? is true but paths are configured' do
        instance = test_class.new(merge: true, append: 'items')

        expect(instance.appends_at_root?).to be false
      end

      it 'returns true when merge? is true and no paths configured and append is true' do
        instance = test_class.new(merge: true, append: true)

        expect(instance.appends_at_root?).to be true
      end

      it 'returns false when append is explicitly false' do
        instance = test_class.new(merge: true, append: false)

        expect(instance.appends_at_root?).to be false
      end
    end

    describe '#prepends_at_root?' do
      it 'returns false when merge? is false' do
        instance = test_class.new(merge: false)

        expect(instance.prepends_at_root?).to be false
      end

      it 'returns false when merge? is true but paths are configured' do
        instance = test_class.new(merge: true, prepend: 'items')

        expect(instance.prepends_at_root?).to be false
      end

      it 'returns true when merge? is true and no paths configured and append is false' do
        instance = test_class.new(merge: true, append: false)

        expect(instance.prepends_at_root?).to be true
      end

      it 'returns false when prepend sets append to true' do
        instance = test_class.new(merge: true, prepend: false)

        expect(instance.prepends_at_root?).to be false
      end
    end
  end

  describe 'complex path handling' do
    it 'handles mixed append/prepend configurations' do
      instance = test_class.new(
        merge: true,
        append: %w[items categories],
        prepend: 'featured_products'
      )

      expect(instance.appends_at_paths).to include('items', 'categories')
      expect(instance.prepends_at_paths).to include('featured_products')
      expect(instance.merges_at_root?).to be false
    end

    it 'handles nested path configurations with match_on' do
      instance = test_class.new(
        append: { 'users.posts' => 'id', 'users.comments' => 'created_at' }
      )

      expect(instance.appends_at_paths).to include('users.posts', 'users.comments')
      expect(instance.match_on).to include('users.posts.id', 'users.comments.created_at')
    end

    it 'accumulates match_on patterns from multiple configurations' do
      instance = test_class.new(
        match_on: ['existing'],
        append: { items: 'id' },
        prepend: { products: 'slug' }
      )

      expect(instance.match_on).to include('existing', 'items.id', 'products.slug')
    end
  end

  describe 'string interpolation for match_on patterns' do
    it 'correctly formats path.match_on patterns' do
      instance = test_class.new(merge: true, append: { 'users.posts' => 'id' })

      expect(instance.match_on).to include('users.posts.id')
    end

    it 'handles complex nested paths' do
      instance = test_class.new(
        append: { 'api.v1.users.posts' => 'uuid' }
      )

      expect(instance.match_on).to include('api.v1.users.posts.uuid')
    end

    it 'handles special characters in paths' do
      instance = test_class.new(
        append: { 'user-data_items' => 'item-id' }
      )

      expect(instance.match_on).to include('user-data_items.item-id')
    end
  end

  describe 'edge cases' do
    it 'handles empty arrays' do
      instance = test_class.new(merge: true, append: [], prepend: [])

      expect(instance.appends_at_paths).to be_empty
      expect(instance.prepends_at_paths).to be_empty
      expect(instance.merges_at_root?).to be true
    end

    it 'handles empty hashes' do
      instance = test_class.new(merge: true, append: {}, prepend: {})

      expect(instance.appends_at_paths).to be_empty
      expect(instance.prepends_at_paths).to be_empty
      expect(instance.match_on).to be_empty
    end

    it 'handles numeric paths converted to strings' do
      instance = test_class.new(merge: true, append: { 123 => 'id' })

      expect(instance.appends_at_paths).to include('123')
      expect(instance.match_on).to include('123.id')
    end

    it 'handles symbol paths converted to strings' do
      instance = test_class.new(merge: true, append: { items: :id })

      expect(instance.appends_at_paths).to include('items')
      expect(instance.match_on).to include('items.id')
    end
  end

  describe 'interaction with superclass' do
    let(:test_class_with_super) do
      Class.new do
        include InertiaRails::PropMergeable

        attr_reader :super_called

        def initialize(**props, &block)
          @super_called = true
          super
        end
      end
    end

    it 'calls super in initialization' do
      instance = test_class_with_super.new

      expect(instance.super_called).to be true
    end
  end
end
