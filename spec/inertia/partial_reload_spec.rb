RSpec.describe 'partial reloads', type: :request do
  describe 'optimization guard rails' do
    context 'when a non-requested prop is defined as a value' do
      let (:fake_std_err) {FakeStdErr.new}
      let (:warn_message) {'[InertiaRails]: WARNING! The :expensive_prop prop is being computed even though your partial reload did not request it because it is defined as a value. You might want to wrap these in a callable like a lambda ->{} or InertiaRails::Lazy().'}
      let (:warn_message_with_multiple) {'[InertiaRails]: WARNING! The :expensive_prop, :another_expensive_prop props are being computed even though your partial reload did not request them because they are defined as values. You might want to wrap these in a callable like a lambda ->{} or InertiaRails::Lazy().'}

      around(:each) do |example|
        begin
          original_stderr = $stderr
          $stderr         = fake_std_err

          example.run
        ensure
          $std_err = original_stderr
        end
      end

      it 'only returns the requested prop' do
        get unoptimized_partial_reloads_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'search',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }

        expect(JSON.parse(response.body)['props'].deep_symbolize_keys).to eq({
          search: {
            query: '',
            results: [],
          },
        })
      end

      it 'computes the non-requested prop anyway' do
        expect_any_instance_of(InertiaUnoptimizedPartialReloadsController).to receive(:expensive_prop).with(any_args)

        get unoptimized_partial_reloads_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'search',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      it 'emits a warning' do
        get unoptimized_partial_reloads_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'search',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
        expect(fake_std_err.messages[0].chomp).to(eq(warn_message))
      end

      it 'does not warn about callable props' do
        get unoptimized_partial_reloads_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'search',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }

        expect(fake_std_err.messages[0].chomp).not_to include('callable_prop')
      end

      context 'when there are multiple non-requested props defined as values' do
        it 'emits a different warning' do
          get unoptimized_partial_reloads_with_mutiple_path, headers: {
            'X-Inertia' => true,
            'X-Inertia-Partial-Data' => 'search',
            'X-Inertia-Partial-Component' => 'TestComponent',
          }

          expect(fake_std_err.messages[0].chomp).to(eq(warn_message_with_multiple))
        end
      end

      context 'when the controller is configured to raise_on_unoptimized_partial_reloads' do
        it 'emits a warning' do
          expect {
            get has_searchable_path, headers: {
              'X-Inertia' => true,
              'X-Inertia-Partial-Data' => 'search',
              'X-Inertia-Partial-Component' => 'TestComponent',
            }
          }.to raise_error(InertiaRails::UnoptimizedPartialReloadError, /unrequested_prop/)
        end
      end
    end
  end
end
