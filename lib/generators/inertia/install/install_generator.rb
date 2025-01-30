# frozen_string_literal: true

require 'yaml'
require 'rails/generators'
require 'rails/generators/base'

require_relative 'helpers'
require_relative 'js_package_manager'

module Inertia
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Helpers

      FRAMEWORKS = YAML.load_file(File.expand_path('./frameworks.yml', __dir__))

      source_root File.expand_path('./templates', __dir__)

      class_option :framework, type: :string,
                               desc: 'The framework you want to use with Inertia',
                               enum: FRAMEWORKS.keys,
                               default: nil

      class_option :inertia_version, type: :string, default: 'latest',
                                     desc: 'The version of Inertia.js to install'

      class_option :typescript, type: :boolean, default: false,
                                desc: 'Whether to use TypeScript'

      class_option :package_manager, type: :string, default: nil,
                                     enum: JSPackageManager.package_managers,
                                     desc: "The package manager you want to use to install Inertia's npm packages"

      class_option :interactive, type: :boolean, default: true,
                                 desc: 'Whether to prompt for optional installations'

      class_option :tailwind, type: :boolean, default: false,
                              desc: 'Whether to install Tailwind CSS'
      class_option :vite, type: :boolean, default: false,
                          desc: 'Whether to install Vite Ruby'
      class_option :example_page, type: :boolean, default: true,
                                  desc: 'Whether to add an example Inertia page'

      class_option :verbose, type: :boolean, default: false,
                             desc: 'Run the generator in verbose mode'

      remove_class_option :skip_namespace, :skip_collision_check

      def install
        say "Installing Inertia's Rails adapter"

        if inertia_resolved_version.version == '0'
          say_error "Could not find the Inertia.js package version #{options[:inertia_version]}.", :red
          exit(false)
        end

        install_vite unless ruby_vite_installed?

        install_typescript if typescript?

        install_tailwind if install_tailwind?

        install_inertia

        install_example_page if options[:example_page]

        say 'Copying bin/dev'
        copy_file "#{__dir__}/templates/dev", 'bin/dev'
        chmod 'bin/dev', 0o755, verbose: verbose?

        say "Inertia's Rails adapter successfully installed", :green
      end

      private

      def install_inertia
        say "Adding Inertia's Rails adapter initializer"
        template 'initializer.rb', file_path('config/initializers/inertia_rails.rb')

        say 'Installing Inertia npm packages'
        add_dependencies(inertia_package, *FRAMEWORKS[framework]['packages'])

        unless File.read(vite_config_path).include?(FRAMEWORKS[framework]['vite_plugin_import'])
          say "Adding Vite plugin for #{framework}"
          insert_into_file vite_config_path, "\n    #{FRAMEWORKS[framework]['vite_plugin_call']},", after: 'plugins: ['
          prepend_file vite_config_path, "#{FRAMEWORKS[framework]['vite_plugin_import']}\n"
        end

        say "Copying #{inertia_entrypoint} entrypoint"
        template "#{framework}/#{inertia_entrypoint}", js_file_path("entrypoints/#{inertia_entrypoint}")

        if application_layout.exist?
          say "Adding #{inertia_entrypoint} script tag to the application layout"
          headers = <<-ERB
    <%= #{vite_tag} "inertia" %>
    <%= inertia_ssr_head %>
          ERB
          insert_into_file application_layout.to_s, headers, after: "<%= vite_client_tag %>\n"

          if framework == 'react' && !application_layout.read.include?('vite_react_refresh_tag')
            say 'Adding Vite React Refresh tag to the application layout'
            insert_into_file application_layout.to_s, "<%= vite_react_refresh_tag %>\n    ",
                             before: '<%= vite_client_tag %>'
          end

          gsub_file application_layout.to_s, /<title>/, '<title inertia>' unless svelte?
        else
          say_error 'Could not find the application layout file. Please add the following tags manually:', :red
          say_error '-  <title>...</title>'
          say_error '+  <title inertia>...</title>'
          say_error '+  <%= inertia_ssr_head %>'
          say_error '+  <%= vite_react_refresh_tag %>' if framework == 'react'
          say_error "+  <%= #{vite_tag} \"inertia\" %>"
        end
      end

      def install_typescript
        say 'Adding TypeScript support'
        if svelte? && inertia_resolved_version.release < Gem::Version.new('1.3.0')
          say 'WARNING: @inertiajs/svelte < 1.3.0 does not support TypeScript ' \
              "(resolved version: #{inertia_resolved_version}).",
              :yellow
          say 'Skipping TypeScript support for @inertiajs/svelte', :yellow
          @typescript = false
          return
        end

        add_dependencies(*FRAMEWORKS[framework]['packages_ts'])

        say 'Copying adding scripts to package.json'
        run 'npm pkg set scripts.check="svelte-check --tsconfig ./tsconfig.json && tsc -p tsconfig.node.json"' if svelte?
        run 'npm pkg set scripts.check="vue-tsc -p tsconfig.app.json && tsc -p tsconfig.node.json"' if framework == 'vue'
        run 'npm pkg set scripts.check="tsc -p tsconfig.app.json && tsc -p tsconfig.node.json"' if framework == 'react'
      end

      def install_example_page
        say 'Copying example Inertia controller'
        template 'controller.rb', file_path('app/controllers/inertia_example_controller.rb')

        say 'Adding a route for the example Inertia controller'
        route "get 'inertia-example', to: 'inertia_example#index'"

        say 'Copying page assets'
        copy_files = FRAMEWORKS[framework]['copy_files'].merge(
          FRAMEWORKS[framework]["copy_files_#{typescript? ? 'ts' : 'js'}"]
        )
        copy_files.each do |source, destination|
          template "#{framework}/#{source}", file_path(format(destination, js_destination_path: js_destination_path))
        end
      end

      def install_tailwind
        say 'Installing Tailwind CSS'
        add_dependencies(%w[tailwindcss @tailwindcss/vite @tailwindcss/forms @tailwindcss/typography])
        prepend_file vite_config_path, "import tailwindcss from '@tailwindcss/vite'\n"
        insert_into_file vite_config_path, "\n    tailwindcss(),", after: 'plugins: ['
        copy_file 'tailwind/application.css', js_file_path('entrypoints/application.css')

        if application_layout.exist?
          say 'Adding Tailwind CSS to the application layout'
          insert_into_file application_layout.to_s, "<%= vite_stylesheet_tag \"application\" %>\n    ",
                           before: '<%= vite_client_tag %>'
        else
          say_error 'Could not find the application layout file. Please add the following tags manually:', :red
          say_error '+  <%= vite_stylesheet_tag "application" %>' if install_tailwind?
        end
      end

      def install_vite
        unless install_vite?
          say_error 'This generator only supports Ruby on Rails with Vite.', :red
          exit(false)
        end

        in_root do
          Bundler.with_original_env do
            if (capture = run('bundle add vite_rails', capture: !verbose?))
              say 'Vite Rails gem successfully installed', :green
            else
              say capture
              say_error 'Failed to install Vite Rails gem', :red
              exit(false)
            end
            if (capture = run('bundle exec vite install', capture: !verbose?))
              say 'Vite Rails successfully installed', :green
            else
              say capture
              say_error 'Failed to install Vite Rails', :red
              exit(false)
            end
          end
        end
      end

      def ruby_vite_installed?
        return true if package_manager.present? && ruby_vite?

        if !package_manager.present?
          say_status 'Could not find a package.json file to install Inertia to.', nil
        elsif gem_installed?('webpacker') || gem_installed?('shakapacker')
          say 'Webpacker or Shakapacker is installed.', :yellow
          say 'Vite Ruby can work alongside Webpacker or Shakapacker, but it might cause issues.', :yellow
          say 'Please see the Vite Ruby documentation for the migration guide:', :yellow
          say 'https://vite-ruby.netlify.app/guide/migration.html#webpacker-%F0%9F%93%A6', :yellow
        else
          say_status 'Could not find a Vite configuration files ' \
                     '(`config/vite.json` & `vite.config.{ts,js,mjs,cjs,mts,cts}`).',
                     nil
        end
        false
      end

      def gem_installed?(name)
        regex = /^[^#]*gem\s+['"]#{name}['"]/
        File.read(file_path('Gemfile')).match?(regex)
      end

      def application_layout
        @application_layout ||= Pathname.new(file_path('app/views/layouts/application.html.erb'))
      end

      def ruby_vite?
        file?('config/vite.json') && vite_config_path
      end

      def package_manager
        @package_manager ||= JSPackageManager.new(self)
      end

      def add_dependencies(*packages)
        package_manager.add_dependencies(*packages)
      end

      def vite_config_path
        @vite_config_path ||= Dir.glob(file_path('vite.config.{ts,js,mjs,cjs,mts,cts}')).first
      end

      def install_vite?
        return @install_vite if defined?(@install_vite)

        @install_vite = options[:vite] || yes?('Would you like to install Vite Ruby? (y/n)', :green)
      end

      def install_tailwind?
        return @install_tailwind if defined?(@install_tailwind)

        @install_tailwind = options[:tailwind] || yes?('Would you like to install Tailwind CSS? (y/n)', :green)
      end

      def typescript?
        return @typescript if defined?(@typescript)

        @typescript = options[:typescript] || yes?('Would you like to use TypeScript? (y/n)', :green)
      end

      def inertia_entrypoint
        "inertia.#{typescript? ? 'ts' : 'js'}"
      end

      def vite_tag
        typescript? ? 'vite_typescript_tag' : 'vite_javascript_tag'
      end

      def inertia_resolved_version
        @inertia_resolved_version ||= Gem::Version.new(
          `npm show @inertiajs/core@#{options[:inertia_version]} version --json | tail -n2 | head -n1 | tr -d '", '`.strip
        )
      end

      def verbose?
        options[:verbose]
      end

      def svelte?
        framework.start_with? 'svelte'
      end

      def inertia_package
        "#{FRAMEWORKS[framework]['inertia_package']}@#{options[:inertia_version]}"
      end

      def framework
        @framework ||= options[:framework] || ask('What framework do you want to use with Inertia?', :green,
                                                  limited_to: FRAMEWORKS.keys, default: 'react')
      end
    end
  end
end
