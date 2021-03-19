namespace :inertia_rails do
  namespace :install do
    desc "Installs inertia_rails packages and configurations for a React based app"
    task :react => :environment do
      system 'rails g inertia_rails:install --front_end react'
    end
    desc "Installs inertia_rails packages and configurations for a Vue based app"
    task vue: :environment do
      system 'rails g inertia_rails:install --front_end vue'
    end
    desc "Installs inertia_rails packages and configurations for a Svelte based app"
    task svelte: :environment do
      system 'rails g inertia_rails:install --front_end svelte'
    end
  end
end