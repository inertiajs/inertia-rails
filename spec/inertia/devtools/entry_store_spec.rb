# frozen_string_literal: true

RSpec.describe InertiaRails::Devtools::EntryStore do
  subject(:store) { described_class.new }

  it 'stops touching storage after a write failure, and reports it once' do
    allow(InertiaRails::Devtools).to receive(:report)

    Tempfile.create('not-a-directory') do |file|
      InertiaRails.configuration.devtools.storage_path = File.join(file.path, 'entries')
      2.times { store.write(described_class.generate_id, {}) }
    end
    Dir.mktmpdir do |dir|
      InertiaRails.configuration.devtools.storage_path = dir
      store.write(described_class.generate_id, {})

      expect(store.list).to be_empty
    end
    expect(InertiaRails::Devtools).to have_received(:report).once
  ensure
    InertiaRails.configuration.devtools.storage_path = InertiaRails::Devtools::Config::DEFAULTS[:storage_path]
  end

  it 'resolves a relative storage path against the app root' do
    relative = "tmp/inertia-devtools-spec-#{SecureRandom.hex(4)}"
    InertiaRails.configuration.devtools.storage_path = relative
    id = described_class.generate_id

    store.write(id, {})

    expect(File).to exist(Rails.root.join(relative, '_', "#{id}.json"))
  ensure
    FileUtils.rm_rf(Rails.root.join(relative))
    InertiaRails.configuration.devtools.storage_path = InertiaRails::Devtools::Config::DEFAULTS[:storage_path]
  end

  it 'keeps expiring entries when another process deletes one first' do
    Dir.mktmpdir do |dir|
      InertiaRails.configuration.devtools.storage_path = dir
      stale = 2.times.map { described_class.generate_id }
      stale.each { |id| store.write(id, {}, tab_uuid: 'old-tab') }
      files = stale.map { |id| File.join(dir, 'old-tab', "#{id}.json") }
      files.each { |file| File.utime(2.days.ago.to_time, 2.days.ago.to_time, file) }
      allow(File).to receive(:mtime).and_call_original
      allow(File).to receive(:mtime).with(files.first).and_raise(Errno::ENOENT)

      store.write(described_class.generate_id, {}, tab_uuid: 'new-tab')

      expect(File).not_to exist(files.last)
    end
  ensure
    InertiaRails.configuration.devtools.storage_path = InertiaRails::Devtools::Config::DEFAULTS[:storage_path]
  end

  it 'rejects ids that could reach outside its directory' do
    expect { store.write('../secret', {}) }.to raise_error(ArgumentError, /Invalid/)
  end
end
