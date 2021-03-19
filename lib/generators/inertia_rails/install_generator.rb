module InertiaRails
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('./install', __dir__)
    class_option :front_end, type: :string, default: 'react'

    FRONT_END_INSTALLERS = [
      'react',
    ]

    def install
      exit! unless installable?

      install_base!

      send "install_#{options[:front_end]}!"

      say "You're all set! Run rails s and checkout localhost:3000/inertia-example", :green
    end

    protected

    def installable?
      unless run("./bin/rails webpacker:verify_install")
        say "Sorry, you need to have webpacker installed for inertia_rails default setup.", :red
        return false
      end

      unless options[:front_end].in? FRONT_END_INSTALLERS
        say "Sorry, there is no generator for #{options[:front_end]}!\n\n", :red
        say "If you are a #{options[:front_end]} developer, please help us improve inertia_rails by contributing an installer.\n\n"
        say "https://github.com/inertiajs/inertia-rails/\n\n"

        return false
      end
    end

    def install_base!
      say "Adding inertia pack tag to application layout", :blue
      insert_into_file Rails.root.join("app/views/layouts/application.html.erb").to_s, after: "<%= javascript_pack_tag 'application' %>\n" do
        "\t\t<%= javascript_pack_tag 'inertia' %>\n"
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
      template "react.jsx", Rails.root.join("app/javascript/Pages/InertiaExample.js").to_s
      say "Copying inertia.jsx into webpacker's packs folder...", :blue
      template "inertia.jsx", Rails.root.join("app/javascript/packs/inertia.jsx").to_s
      say "done!", :green
    end
  end
end