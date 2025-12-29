# frozen_string_literal: true

require_relative '../../../lib/generators/inertia/install/install_generator'
require 'generator_spec'

RSpec.describe Inertia::Generators::InstallGenerator, type: :generator do
  destination File.expand_path('../../../tmp', __dir__)

  let(:args) { %W[--framework=#{framework} --no-interactive -q] }
  let(:framework) { :react }
  let(:ext) { 'js' }

  subject(:generator) { run_generator(args) }

  shared_context 'assert framework structure' do
    before { prepare_application }

    it 'installs the Inertia adapter' do
      expect { generator }.not_to raise_error

      expect_example_page_for(framework, ext: ext)
      expect_inertia_prepared_for(framework, ext: ext)
      expect_packages_for(framework, ext: ext)
    end
  end

  shared_context 'assert framework js and ts structures' do
    include_context 'assert framework structure'

    context 'with --typescript' do
      let(:args) { super() + %w[--typescript] }
      let(:ext) { 'ts' }

      include_context 'assert framework structure'
    end
  end

  shared_context 'assert application.js entrypoint renaming' do
    let(:typescript_enabled?) { args.include?('--typescript') }

    it 'renames application.js to application.ts if TypeScript flag is enabled' do
      expect { generator }.not_to raise_error

      if typescript_enabled?
        expect(File.exist?(File.join(destination_root, 'app/frontend/entrypoints/application.ts'))).to be true
        expect(File.exist?(File.join(destination_root, 'app/frontend/entrypoints/application.js'))).to be false
      else
        expect(File.exist?(File.join(destination_root, 'app/frontend/entrypoints/application.js'))).to be true
        expect(File.exist?(File.join(destination_root, 'app/frontend/entrypoints/application.ts'))).to be false
      end
    end
  end

  context 'without vite' do
    before do
      prepare_application(with_vite: false)
    end

    it 'exits with an error' do
      expect { generator }.to raise_error(SystemExit)
    end

    context 'with --vite' do
      let(:args) { super() + %w[--vite] }

      it 'installs Vite' do
        expect { generator }.not_to raise_error
        expect_example_page_for(:react)
        expect_packages_for(:react)
        expect(destination_root).to(have_structure do
          directory('app/frontend') do
            no_file('entrypoints/application.css')
          end
        end)
      end

      include_context 'assert application.js entrypoint renaming'

      context 'with --typescript' do
        let(:args) { super() + %w[--typescript] }

        include_context 'assert application.js entrypoint renaming'
      end
    end
  end

  context 'with --tailwind' do
    let(:args) { super() + %w[--tailwind] }

    before { prepare_application }

    it 'installs Tailwind with vite plugin' do
      expect { generator }.not_to raise_error
      expect_tailwind_config
    end
  end

  context 'with --framework=svelte' do
    let(:framework) { :svelte }

    include_context 'assert framework js and ts structures'
  end

  context 'with --framework=vue' do
    let(:framework) { :vue }

    include_context 'assert framework js and ts structures'
  end

  context 'with --framework=react' do
    let(:framework) { :react }

    include_context 'assert framework js and ts structures'
  end

  def prepare_application(with_vite: true)
    prepare_destination
    FileUtils.cp_r(Dir['spec/fixtures/install_generator/dummy/*'], destination_root)
    FileUtils.cp_r(Dir['spec/fixtures/install_generator/with_vite/*'], destination_root) if with_vite
  end

  def expect_tailwind_config
    expect(destination_root).to(have_structure do
      directory('app/frontend') do
        file('entrypoints/application.css') do
          contains("@import 'tailwindcss';")
        end
      end
      file('package.json') do
        contains('"tailwindcss":')
        contains('"@tailwindcss/vite":')
      end
      file('vite.config.ts') do
        contains('tailwindcss(),')
      end
    end)
  end

  def expect_vite_config
    expect(destination_root).to(have_structure do
      directory('config') do
        file('vite.json')
      end
      file('vite.config.js')
    end)
  end

  def expect_packages_for(framework, ext: 'js')
    expect(destination_root).to(have_structure do
      file('package.json') do
        case framework
        when :react
          contains('"@inertiajs/react":')
          contains('"react":')
          contains('"react-dom":')
          contains('"@vitejs/plugin-react":')
          if ext == 'ts'
            contains('"@types/react":')
            contains('"@types/react-dom":')
            contains('"typescript":')
          end
        when :vue
          contains('"@inertiajs/vue3":')
          contains('"vue":')
          contains('"@vitejs/plugin-vue":')
          if ext == 'ts'
            contains('"typescript":')
            contains('"vue-tsc":')
          end
        when :svelte
          contains('"@inertiajs/svelte":')
          contains('"svelte":')
          contains('"@sveltejs/vite-plugin-svelte":')
          if ext == 'ts'
            contains('"@tsconfig/svelte":')
            contains('"svelte-check":')
            contains('"typescript":')
            contains('"tslib":')
          end
        end
      end
    end)
  end

  def expect_inertia_prepared_for(framework, ext: 'js', application_js_exists: false)
    expect(destination_root).to(have_structure do
      case framework
      when :react
        file('vite.config.ts') do
          contains('react()')
        end
        file("app/frontend/entrypoints/inertia.#{ext}x") do
          contains("from '@inertiajs/react'")
        end
      when :vue
        file('vite.config.ts') do
          contains('vue()')
        end
        file("app/frontend/entrypoints/inertia.#{ext}") do
          contains("from '@inertiajs/vue3'")
        end
      when :svelte
        file('svelte.config.js') do
          contains('preprocess: vitePreprocess()')
        end
        file('vite.config.ts') do
          contains('svelte()')
        end
        file("app/frontend/entrypoints/inertia.#{ext}") do
          if ext == 'ts'
            contains("import { createInertiaApp, type ResolvedComponent } from '@inertiajs/svelte'")
          else
            contains("from '@inertiajs/svelte'")
          end
          contains('mount(App, { target: el, props })')
        end
      end
      file('app/views/layouts/application.html.erb') do
        if ext == 'ts' && application_js_exists
          contains("<%= vite_typescript_tag \"inertia#{'.tsx' if framework == :react}\" %>")
          contains("<%= vite_typescript_tag 'application' %>")
        elsif ext == 'ts' && !application_js_exists
          contains("<%= vite_typescript_tag \"inertia#{'.tsx' if framework == :react}\" %>")
          contains("<%= vite_javascript_tag 'application' %>")
        else
          contains("<%= vite_javascript_tag \"inertia#{'.jsx' if framework == :react}\" %>")
          contains("<%= vite_javascript_tag 'application' %>")
        end
        if framework == :react
          contains('<%= vite_react_refresh_tag %>')
        else
          does_not_contain('<%= vite_react_refresh_tag %>')
        end
      end
      file('config/initializers/inertia_rails.rb') do
        contains('config.version = ViteRuby.digest')
      end

      file('bin/dev') do
        contains('overmind start -f Procfile.dev')
      end

      file('bin/vite')

      if ext == 'ts'
        file('app/frontend/types/vite-env.d.ts') do
          contains('/// <reference types="vite/client" />')
        end
        file('app/frontend/types/globals.d.ts') do
          contains('export interface InertiaConfig')
        end
        file('app/frontend/types/index.ts') do
          contains('export type SharedProps')
        end
        file('tsconfig.node.json') do
          contains('"include": ["vite.config.ts"]')
        end
        case framework
        when :react
          file('tsconfig.json') do
            contains('"path": "./tsconfig.app.json"')
          end
          file('tsconfig.app.json') do
            contains('"include": ["app/frontend"]')
          end
        when :vue
          file('tsconfig.json') do
            contains('"path": "./tsconfig.app.json"')
          end
          file('tsconfig.app.json') do
            contains('"include": ["app/frontend/**/*.ts", "app/frontend/**/*.tsx", "app/frontend/**/*.vue"]')
          end
        when :svelte
          file('tsconfig.json') do
            contains('"include": ["app/frontend/**/*.ts", "app/frontend/**/*.js", "app/frontend/**/*.svelte"]')
          end
        end
      end
    end)
  end

  def expect_example_page_for(framework, ext: 'js')
    expect(destination_root).to(have_structure do
      directory('app/frontend') do
        case framework
        when :react
          file("pages/inertia_example/index.#{ext == 'js' ? 'jsx' : 'tsx'}")
          file('pages/inertia_example/index.module.css')
          file('assets/react.svg')
        when :vue
          file('pages/inertia_example/index.vue')
          file('assets/vue.svg')
        when :svelte
          file('pages/inertia_example/index.svelte') do
            if ext == 'ts'
              contains('let { rails_version, rack_version, ruby_version, inertia_rails_version }:')
            else
              contains('let { rails_version, rack_version, ruby_version, inertia_rails_version } = $props()')
            end
          end
          file('assets/svelte.svg')
        end

        file('assets/rails.svg')
        file('assets/inertia.svg')
        file('assets/vite_ruby.svg')
      end
    end)
  end
end
