require_relative '../../lib/inertia_rails/rspec'

RSpec.describe InertiaRails::RSpec, type: :request do
  describe 'correctly set up inertia tests with inertia: true', inertia: true do
    context 'with props' do
      before { get props_path }

      it 'has props' do
        expect_inertia.to have_exact_props({name: 'Brandon', sport: 'hockey'})
      end

      it 'includes props' do
        expect_inertia.to include_props({sport: 'hockey'})
      end

      it 'can retrieve props' do
        expect(inertia.props[:name]).to eq 'Brandon'
      end
    end

    context 'with view data' do
      before { get view_data_path }

      it 'has view data' do
        expect_inertia.to have_exact_view_data({name: 'Brian', sport: 'basketball'})
      end

      it 'includes view data' do
        expect_inertia.to include_view_data({sport: 'basketball'})
      end

      it 'can retrieve view data' do
        expect(inertia.view_data[:name]).to eq 'Brian'
      end
    end

    context 'with component name' do
      before { get component_path }

      it 'has the component name' do
        expect_inertia.to render_component 'TestComponent'
      end

      it 'can retrieve the component name' do
        expect(inertia.component).to eq 'TestComponent'
      end
    end
  end

  describe 'inertia tests missing the inertia: true flag' do
    before { get component_path }

    it 'warns you to add inertia: true' do
      expect { expect_inertia }.to raise_error(/inertia: true/)
    end
  end
end
