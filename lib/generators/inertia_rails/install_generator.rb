module InertiaRails
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('./install', __dir__)
    class_option :front_end, type: :string, default: 'react'

    FRONT_END_INSTALLERS = [
      'react',
      'vue',
      'svelte',
    ]

    def install
      exit! unless installable?

      @vite_source_code_dir = vite_source_code_dir if @vite_installed?
      install_base!

      send "install_#{options[:front_end]}!"

      say "You're all set! Run rails s and checkout localhost:3000/inertia-example", :green
    end

    protected

    def installable?
      @vite_installed? = run("./bin/rails vite:verify_install")
      unless @vite_installed? || run("./bin/rails webpacker:verify_install")
        say "Sorry, you need to have vite or webpacker installed for inertia_rails default setup.", :red
        return false
      end

      unless options[:front_end].in? FRONT_END_INSTALLERS
        say "Sorry, there is no generator for #{options[:front_end]}!\n\n", :red
        say "If you are a #{options[:front_end]} developer, please help us improve inertia_rails by contributing an installer.\n\n"
        say "https://github.com/inertiajs/inertia-rails/\n\n"

        return false
      end

      true
    end

    def install_base!
      say "Adding inertia pack tag to application layout", :blue
      if @vite_installed?
        insert_into_file Rails.root.join("app/views/layouts/application.html.erb").to_s, after: "<%= vite_javascript_tag 'application' %>\n" do
          "\t\t<%= vite_javascript_tag 'inertia' %>\n"
        end
      else
        insert_into_file Rails.root.join("app/views/layouts/application.html.erb").to_s, after: "<%= javascript_pack_tag 'application' %>\n" do
          "\t\t<%= javascript_pack_tag 'inertia' %>\n"
        end
      end

      say "Installing inertia client packages", :blue
      run "yarn add @inertiajs/inertia @inertiajs/progress"

      say "Copying example files", :blue
      template "controller.rb", Rails.root.join("app/controllers/inertia_example_controller.rb").to_s

      say "Adding a route for the example inertia controller...", :blue
      route "get 'inertia-example', to: 'inertia_example#index'"
    end

    def install_react!
      say "Creating a React page component...", :blue
      run 'yarn add @inertiajs/inertia-react'
      template "react/InertiaExample.jsx", Rails.root.join("#{ source_code_path }Pages/InertiaExample.js").to_s
      say "Copying inertia.jsx into #{ @vite_installed ? "vite's entrypoints folder" : "webpacker's packs folder" }...", :blue
      template "react/inertia.jsx", Rails.root.join("#{ packs_path }inertia.jsx").to_s
      say "done!", :green
    end

    def install_vue!
      say "Creating a Vue page component...", :blue
      run 'yarn add @inertiajs/inertia-vue'
      template "vue/InertiaExample.vue", Rails.root.join("#{ source_code_path }Pages/InertiaExample.vue").to_s
      say "Copying inertia.js into #{ @vite_installed ? "vite's entrypoints folder" : "webpacker's packs folder" }...", :blue
      template "vue/inertia.js", Rails.root.join("#{ packs_path }inertia.js").to_s
      say "done!", :green
    end

    def install_svelte!
      say "Creating a Svelte page component...", :blue
      run 'yarn add @inertiajs/inertia-svelte'
      template "svelte/InertiaExample.svelte", Rails.root.join("#{source_code_path}Pages/InertiaExample.svelte").to_s
      say "Copying inertia.js into #{ @vite_installed ? "vite's entrypoints folder" : "webpacker's packs folder" }...", :blue
      template "svelte/inertia.js", Rails.root.join("#{packs_path}inertia.js").to_s
      say "done!", :green
    end

    def vite_source_code_dir
      vite_config = JSON.parse(File.read("config/vite.json"))
      source_code_dir = vite_config["all"]["sourceCodeDir"]
      source_code_dir = "#{source_code_dir}/" unless source_code_dir.last == "/"

      source_code_dir
    end

    def source_code_path
      @vite_installed? ? @vite_source_code_dir : "app/javascript/"
    end

    def packs_path
      @vite_installed? ? "#{ @vite_source_code_dir }entrypoints/" : "app/javascript/packs/"
    end
  end
end
