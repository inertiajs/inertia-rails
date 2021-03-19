module InertiaRails
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('./install', __dir__)

    def install
      say "Copying inertia.jsx into webpacker's packs folder..."

      template "inertia.jsx", Rails.root.join("app/javascript/packs/inertia.jsx").to_s
      say "done!", :green

      say "Adding inertia pack tag to application layout"
      insert_into_file Rails.root.join("app/views/layouts/application.html.erb").to_s, after: "<%= javascript_pack_tag 'application' %>\n" do
        "\t\t<%= javascript_pack_tag 'inertia' %>\n"
      end

      say "Installing inertia client packages"
      run "yarn add @inertiajs/inertia @inertiajs/inertia-react @inertiajs/progress"

      say "Copying example files"
      template "controller.rb", Rails.root.join("app/controllers/inertia_example_controller.rb").to_s
      template "react.jsx", Rails.root.join("app/javascript/Pages/InertiaExample.js").to_s
      route "get 'inertia-example', to: 'inertia_example#index'"

      say "You're all set! Run rails s and checkout localhost:3000/inertia-example"
    end
  end
end