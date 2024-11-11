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

  context 'without vite' do
    before do
      prepare_application(with_vite: false)
    end

    it 'exits with an error' do
      expect { generator }.to raise_error(SystemExit)
    end

    context 'with --install-vite' do
      let(:args) { super() + %w[--install-vite] }

      it 'installs Vite' do
        expect { generator }.not_to raise_error
        expect_example_page_for(:react)
        expect_packages_for(:react)
        expect(destination_root).to(have_structure do
          directory('app/frontend') do
            no_file('entrypoints/application.css')
          end
          no_file('postcss.config.js')
          no_file('tailwind.config.js')
        end)
      end
    end
  end

  context 'with --install-tailwind' do
    let(:args) { super() + %w[--install-tailwind] }

    before { prepare_application }

    it 'installs Tailwind' do
      expect { generator }.not_to raise_error
      expect_tailwind_config
    end
  end

  context 'with --framework=svelte' do
    let(:framework) { :svelte }
    include_context 'assert framework structure'

    context 'with --typescript' do
      let(:inertia_version) { '1.3.0-beta.1' }
      let(:args) { super() + %W[--typescript --inertia-version=#{inertia_version}] }
      let(:ext) { 'ts' }

      include_context 'assert framework structure'

      context 'with old Inertia version' do
        let(:inertia_version) { '1.2.0' }
        let(:ext) { 'js' }

        include_context 'assert framework structure'
      end
    end
  end

  context 'with --framework=svelte4' do
    let(:framework) { :svelte4 }
    include_context 'assert framework structure'

    context 'with --typescript' do
      let(:inertia_version) { '1.3.0-beta.1' }
      let(:args) { super() + %W[--typescript --inertia-version=#{inertia_version}] }
      let(:ext) { 'ts' }

      include_context 'assert framework structure'

      context 'with old Inertia version' do
        let(:inertia_version) { '1.2.0' }
        let(:ext) { 'js' }

        include_context 'assert framework structure'
      end
    end
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
        file('entrypoints/application.css')
      end
      file('postcss.config.js')
      file('tailwind.config.js')
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
        when :svelte, :svelte4
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

  def expect_inertia_prepared_for(framework, ext: 'js')
    expect(destination_root).to(have_structure do
      case framework
      when :react
        file('vite.config.ts') do
          contains('react()')
        end
        file("app/frontend/entrypoints/inertia.#{ext}") do
          contains("import { createInertiaApp } from '@inertiajs/react'")
        end
      when :vue
        file('vite.config.ts') do
          contains('vue()')
        end
        file("app/frontend/entrypoints/inertia.#{ext}") do
          contains("import { createInertiaApp } from '@inertiajs/vue3'")
        end
      when :svelte, :svelte4
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
            contains("import { createInertiaApp } from '@inertiajs/svelte'")
          end
          if framework == :svelte4
            contains('new App({ target: el, props })')
          else
            contains('mount(App, { target: el, props })')
          end
        end
      end
      file('app/views/layouts/application.html.erb') do
        if ext == 'ts'
          contains('<%= vite_typescript_tag "inertia" %>')
        else
          contains('<%= vite_javascript_tag "inertia" %>')
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

      if ext == 'ts'
        file('app/frontend/vite-env.d.ts') do
          contains('/// <reference types="vite/client" />')
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
        when :svelte, :svelte4
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
          file("pages/InertiaExample.#{ext == 'js' ? 'jsx' : 'tsx'}")
          file('pages/InertiaExample.module.css')
          file('assets/react.svg')
        when :vue
          file('pages/InertiaExample.vue')
          file('assets/vue.svg')
        when :svelte4
          file('pages/InertiaExample.svelte') do
            if ext == 'ts'
              contains('export let name: string')
            else
              contains('export let name')
            end
          end
          file('assets/svelte.svg')
        when :svelte
          file('pages/InertiaExample.svelte') do
            if ext == 'ts'
              contains('let { name }: { name: string } = $props()')
            else
              contains('let { name } = $props()')
            end
          end
          file('assets/svelte.svg')
        end

        file('assets/inertia.svg')
        file('assets/vite_ruby.svg')
      end
    end)
  end
end
