# frozen_string_literal: true

require_relative 'lib/inertia_rails/version'

Gem::Specification.new do |spec|
  spec.name          = 'inertia_rails'
  spec.version       = InertiaRails::VERSION
  spec.authors       = ['Brian Knoles', 'Brandon Shar', 'Eugene Granovsky']
  spec.email         = ['brian@bellawatt.com', 'brandon@bellawatt.com', 'eugene@bellawatt.com']

  spec.summary       = 'Inertia.js adapter for Rails'
  spec.description   = 'Quickly build modern single-page React, Vue and Svelte apps ' \
                       'using classic server-side routing and controllers.'
  spec.homepage      = 'https://github.com/inertiajs/inertia-rails'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.0'

  spec.metadata = {
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'changelog_uri' => "#{spec.homepage}/blob/master/CHANGELOG.md",
    'documentation_uri' => "#{spec.homepage}/blob/master/README.md",
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'rubygems_mfa_required' => 'true',
  }

  spec.files = Dir['{app,lib}/**/*', 'CHANGELOG.md', 'LICENSE.txt', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'railties', '>= 6'
end
