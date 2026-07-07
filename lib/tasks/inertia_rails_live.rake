# frozen_string_literal: true

namespace :inertia_rails do
  namespace :live do
    desc 'Emit the live-props wire contract fixture (OUT=path, default spec/fixtures/contracts/v1.json)'
    task contracts: :environment do
      require 'inertia_rails/testing/live_contracts'

      out = ENV['OUT'] || 'spec/fixtures/contracts/v1.json'
      FileUtils.mkdir_p(File.dirname(out))
      File.write(out, InertiaRails::Testing::LiveContracts.to_json_file)
      puts "wrote #{out}"
    end
  end
end
