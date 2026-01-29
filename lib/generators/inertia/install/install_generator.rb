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

        install_vite unless ruby_vite_installed?

        install_typescript if typescript?

        install_tailwind if install_tailwind?

        install_inertia

        install_example_page if options[:example_page]

        say 'Copying bin/dev'
        copy_file 'dev', 'bin/dev'
        chmod 'bin/dev', 0o755, verbose: verbose?

        if install_vite?
          say 'Adding redirect to localhost'
          routing_code = <<~RUBY
            \n  # Redirect to localhost from 127.0.0.1 to use same IP address with Vite server
              constraints(host: "127.0.0.1") do
                get "(*path)", to: redirect { |params, req| "\#{req.protocol}localhost:\#{req.port}/\#{params[:path]}" }
              end
          RUBY

          route routing_code
        end

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
        copy_file "#{framework}/#{inertia_entrypoint}", js_file_path("entrypoints/#{inertia_entrypoint}")

        # Copy framework-specific config files
        if svelte?
          say 'Copying svelte.config.js'
          copy_file 'svelte/svelte.config.js', file_path('svelte.config.js')
        end

        say 'Copying InertiaController'
        copy_file 'inertia_controller.rb', file_path('app/controllers/inertia_controller.rb')

        if application_layout.exist?
          say "Adding #{inertia_entrypoint} script tag to the application layout"
          headers = <<-ERB
    <%= #{vite_tag} %>
    <%= inertia_ssr_head %>
          ERB
          insert_into_file application_layout.to_s, headers, after: "<%= vite_client_tag %>\n"

          if react? && !application_layout.read.include?('vite_react_refresh_tag')
            say 'Adding Vite React Refresh tag to the application layout'
            insert_into_file application_layout.to_s, "<%= vite_react_refresh_tag %>\n    ",
                             before: '<%= vite_client_tag %>'
          end

          gsub_file application_layout.to_s, /<title>/, '<title data-inertia>' unless svelte?
        else
          say_error 'Could not find the application layout file. Please add the following tags manually:', :red
          say_error '-  <title>...</title>'
          say_error '+  <title data-inertia>...</title>'
          say_error '+  <%= inertia_ssr_head %>'
          say_error '+  <%= vite_react_refresh_tag %>' if react?
          say_error "+  <%= #{vite_tag} %>"
        end
      end

      def install_typescript
        say 'Adding TypeScript support'

        add_dependencies(*FRAMEWORKS[framework]['packages_ts'])

        say 'Copying tsconfig and types'

        # Copy tsconfig files
        tsconfig_files = %w[tsconfig.json tsconfig.node.json]
        tsconfig_files << 'tsconfig.app.json' unless svelte?

        tsconfig_files.each do |file|
          template "#{framework}/#{file}", file_path(file)
        end

        # Copy type definition files
        types_files = %w[types/vite-env.d.ts types/globals.d.ts types/index.ts]
        types_files.each do |file|
          template "#{framework}/#{file}", file_path("#{js_destination_path}/#{file}")
        end

        say 'Adding TypeScript check scripts to package.json'
        update_package_json do |package_json|
          package_json['scripts'] ||= {}
          package_json['scripts']['check'] =
            if svelte?
              'svelte-check --tsconfig ./tsconfig.json && tsc -p tsconfig.node.json'
            elsif react?
              'tsc -p tsconfig.app.json && tsc -p tsconfig.node.json'
            elsif vue?
              'vue-tsc -p tsconfig.app.json && tsc -p tsconfig.node.json'
            end
        end
      end

      def install_example_page
        say 'Copying example Inertia controller'
        template 'controller.rb', file_path('app/controllers/inertia_example_controller.rb')

        say 'Adding a route for the example Inertia controller'
        route "get 'inertia-example', to: 'inertia_example#index'"
        route "root 'inertia_example#index'" unless File.read(file_path('config/routes.rb')).match?(/^\s*root\s+/)

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
              rename_application_js_to_ts if typescript?
              run('bundle binstub vite_ruby', capture: !verbose?) unless File.exist?(file_path('bin/vite'))
              say 'Vite Rails successfully installed', :green
            else
              say capture
              say_error 'Failed to install Vite Rails', :red
              exit(false)
            end

            add_package_manager_to_bin_setup
          end
        end
      end

      def rename_application_js_to_ts
        return unless File.exist?(application_js_path)
        return unless application_layout.read.include?("<%= vite_javascript_tag 'application' %>")

        FileUtils.mv(application_js_path, application_ts_path)
        gsub_file application_layout.to_s, /<%= vite_javascript_tag 'application' %>/,
                  "<%= vite_typescript_tag 'application' %>"
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

      def application_js_path
        js_file_path('entrypoints/application.js')
      end

      def application_ts_path
        js_file_path('entrypoints/application.ts')
      end

      def inertia_entrypoint
        "inertia.#{typescript? ? 'ts' : 'js'}#{'x' if react?}"
      end

      def vite_tag
        tag = typescript? ? 'vite_typescript_tag' : 'vite_javascript_tag'
        filename = "\"#{react? ? inertia_entrypoint : 'inertia'}\""
        "#{tag} #{filename}"
      end

      def verbose?
        options[:verbose]
      end

      def svelte?
        framework.start_with? 'svelte'
      end

      def react?
        framework.start_with? 'react'
      end

      def vue?
        framework.start_with? 'vue'
      end

      def inertia_package
        "#{FRAMEWORKS[framework]['inertia_package']}@#{options[:inertia_version]}"
      end

      def framework
        @framework ||= options[:framework] || ask('What framework do you want to use with Inertia?', :green,
                                                  limited_to: FRAMEWORKS.keys, default: 'react')
      end

      def add_package_manager_to_bin_setup
        setup_file = file_path('bin/setup')
        return unless File.exist?(setup_file)

        content = File.read(setup_file)
        pm_name = package_manager.name

        # Check if package manager install already exists
        return if content.include?("#{pm_name} install")

        if content.include?('system("bundle check") || system!("bundle install")')
          say 'Adding package manager install to bin/setup'
          cmd = "system! \"#{pm_name} install\""
          insert_into_file setup_file, "\n  #{cmd}",
                           after: 'system("bundle check") || system!("bundle install")'
        else
          say_status "Couldn't add `#{cmd}` script to bin/setup, add it manually", :red
        end
      end
    end
  end
end
