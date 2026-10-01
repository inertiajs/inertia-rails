# frozen_string_literal: true

RSpec.describe InertiaRails::Devtools::SourceLocator do
  it 'has no source when no public method backs the action' do
    hidden = Class.new do
      private

      def index; end
    end

    expect(described_class.method_source(Class.new, :index)).to be_nil
    expect(described_class.method_source(hidden, :index)).to be_nil
  end

  it 'skips gems installed inside the app' do
    bundle = Rails.root.join('vendor/ruby/3.4.0')
    allow(Bundler).to receive(:bundle_path).and_return(bundle)
    gem_frame = instance_double(Thread::Backtrace::Location, absolute_path: bundle.join('gems/alba/lib/alba.rb').to_s)
    app_frame = instance_double(Thread::Backtrace::Location, absolute_path: Rails.root.join('app/x.rb').to_s, lineno: 7)

    expect(described_class.caller_source([gem_frame, app_frame])).to eq(file: Rails.root.join('app/x.rb').to_s, line: 7)
  end

  describe '.key_sources', if: InertiaRails::Devtools::SourceLocator.prism? do
    let(:file) do
      Tempfile.create(['controller', '.rb']).tap do |io|
        io.write(<<~RUBY)
          render inertia: 'Users/Show', props: {
            user: User.find_by(name: params[:name]),
            name: 'Brandon',
            'title' => 'Hi',
            auth: { badge: 'A' },
          }
        RUBY
        io.close
      end.path
    end

    it 'finds the line of each key inside the call, or falls back to the call' do
      sources = described_class.key_sources({ file: file, line: 1 }, %w[name title auth.badge missing])

      expect(sources.transform_values { |source| source[:line] })
        .to eq('name' => 3, 'title' => 4, 'auth.badge' => 5, 'missing' => 1)
    end
  end
end
