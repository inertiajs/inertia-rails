namespace :inertia_rails do
  desc "Installs inertia_rails packages and configurations for a React based app"
  task :install => :environment do
    system 'rails g inertia_rails:install'
  end
end