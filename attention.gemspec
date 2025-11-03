require_relative "lib/attention/version"

Gem::Specification.new do |spec|
  spec.name        = "attention"
  spec.version     = Attention::VERSION
  spec.authors     = ["Attention Team"]
  spec.email       = ["team@attention.example"]
  spec.homepage    = "https://github.com/attention/attention"
  spec.summary     = "Hierarchical task and priority management for Ruby projects"
  spec.description = "Attention is a Ruby engine gem that provides hierarchical task completion tracking and priority management through INI-based configuration files."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/attention/attention"
  spec.metadata["changelog_uri"] = "https://github.com/attention/attention/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{lib,spec,features}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.3.6"

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "inifile", "~> 3.0"

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "cucumber", "~> 9.0"
  spec.add_development_dependency "cucumber-rails", "~> 3.0"
end
