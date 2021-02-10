lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "inertia_rails/version"

Gem::Specification.new do |spec|
  spec.name          = "inertia_rails"
  spec.version       = InertiaRails::VERSION
  spec.authors       = ["Brian Knoles", "Brandon Shar", "Eugene Granovsky"]
  spec.email         = ["brain@bellawatt.com", "brandon@bellawatt.com", "eugene@bellawatt.com"]

  spec.summary       = %q{Inertia adapter for Rails}
  spec.homepage      = "https://github.com/inertiajs/inertia-rails"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rails", '>= 5'

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec-rails", "~> 4.0"
  spec.add_development_dependency "rails-controller-testing"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "responders"
end
