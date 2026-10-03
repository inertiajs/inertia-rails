# frozen_string_literal: true

RSpec.describe InertiaRails::Devtools::Config do
  it 'reads its scalar settings from the environment' do
    with_env('INERTIA_DEVTOOLS_ENABLED' => 'true', 'INERTIA_DEVTOOLS_LIMIT' => '5',
             'INERTIA_DEVTOOLS_STORAGE_PATH' => 'false') do
      config = described_class.new

      expect(config.enabled?).to be true
      expect(config.limit).to eq 5
      expect(config.storage_path).to eq 'false'
    end
  end

  it 'refuses a retention setting that is not a number' do
    with_env('INERTIA_DEVTOOLS_TTL' => 'abc') do
      expect { described_class.new }.to raise_error(ArgumentError)
    end
  end

  it 'takes callables and lists only from code' do
    with_env('INERTIA_DEVTOOLS_AUTHORIZE' => 'true', 'INERTIA_DEVTOOLS_EXCEPT' => 'admin/*') do
      config = described_class.new

      expect(config.authorize).to be_nil
      expect(config.except).to eq []
    end
  end
end
