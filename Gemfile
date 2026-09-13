# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in inertia_rails.gemspec
gemspec

version = ENV.fetch('RAILS_VERSION', '8.1')
rails_main = version == 'main'
rails_number = rails_main ? Float::INFINITY : version.to_f

if rails_main
  gem 'rails', github: 'rails/rails', branch: 'main'
else
  gem 'rails', "~> #{version}.0"
end

gem 'debug'
gem 'generator_spec', '~> 0.10'
gem 'json', '< 3' if rails_number <= 8.1
gem 'puma', rails_number < 7 ? '< 7' : '>= 7'
gem 'rails-controller-testing'
gem 'rake', '~> 13.0'
gem 'responders'
gem 'rspec-rails', '~> 6.0'
gem 'rubocop', '~> 1.21'
gem 'sqlite3'

gem 'kaminari'
gem 'pagy'
