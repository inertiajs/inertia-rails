# frozen_string_literal: true

require 'thor'
require_relative '../../lib/inertia_rails/generators/helper'

RSpec.describe InertiaRails::Generators::Helper, type: :helper do
  describe '#guess_the_default_framework' do
    let(:package_json_path) { Pathname.new(File.expand_path("spec/fixtures/package_json_files/#{fixture_file_name}", Dir.pwd)) }

    shared_examples 'framework detection' do |file_name, expected_framework|
      let(:fixture_file_name) { file_name }

      it "returns #{expected_framework.inspect} when inspect \"#{file_name}\"" do
        expect(described_class.guess_the_default_framework(package_json_path)).to eq(expected_framework)
      end
    end

    it_behaves_like 'framework detection', 'react_package.json', 'react'
    it_behaves_like 'framework detection', 'svelte5_caret_package.json', 'svelte'
    it_behaves_like 'framework detection', 'svelte5_exact_package.json', 'svelte'
    it_behaves_like 'framework detection', 'svelte5_tilde_package.json', 'svelte'
    it_behaves_like 'framework detection', 'svelte4_package.json', 'svelte4'
    it_behaves_like 'framework detection', 'vue_package.json', 'vue'

    # Handle exception
    context 'when framework cannot be determined' do
      let(:fixture_file_name) { 'empty_package.json' }

      it 'raises an error' do
        allow(described_class).to receive(:exit) # Prevent `exit` from terminating the test
        expect(Thor::Shell::Basic).to receive_message_chain(:new, :say_error)
          .with('Could not determine the Inertia.js framework you are using.')
        described_class.guess_the_default_framework(package_json_path)
      end
    end
  end
end
