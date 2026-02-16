# frozen_string_literal: true

require_relative "lib/kyaml/version"

Gem::Specification.new do |spec|
  spec.name = "kyaml-ruby"
  spec.version = KYAML::VERSION
  spec.authors = ["Derek Bender"]
  spec.email = ["170351+djbender@users.noreply.github.com"]

  spec.summary = "Encode Ruby objects as KYAML, a strict flow-style YAML subset"
  spec.description = "KYAML-Ruby encodes Ruby hashes, arrays, and scalars into KYAML — a strict, " \
    "flow-style YAML subset designed to avoid YAML's ambiguity pitfalls. " \
    "API mirrors Ruby's YAML module: require 'kyaml' then KYAML.dump(obj)."
  spec.homepage = "https://github.com/djbender/kyaml-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server when ready to publish"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/djbender/kyaml-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/djbender/kyaml-ruby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .standard.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
