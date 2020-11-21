RSpec.describe InertiaRails::Lazy do
  describe '#call' do
    context 'with a value' do
      it 'returns the value' do
        expect(InertiaRails::Lazy.new('thing').call).to eq('thing')
      end
    end

    context 'with a callable value' do
      it 'returns the result of the callable value' do
        expect(InertiaRails::Lazy.new(->{ 'thing' }).call).to eq('thing')
      end
    end

    context 'with a block' do
      it 'returns the result of the block' do
        expect(InertiaRails::Lazy.new{'thing'}.call).to eq('thing')
      end
    end
  end
end
