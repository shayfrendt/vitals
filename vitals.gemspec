# frozen_string_literal: true

require_relative "lib/vitals/version"

Gem::Specification.new do |spec|
  spec.name = "vitals"
  spec.version = Vitals::VERSION
  spec.authors = ["Shay Frendt"]
  spec.email = ["shay.frendt@gmail.com"]

  spec.summary = "Rails code health assessment tool"
  spec.description = "CLI tool that checks critical maintainability metrics (complexity, code smells, test coverage) for Rails codebases"
  spec.homepage = "https://github.com/shayfrendt/vitals"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/shayfrendt/vitals"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "bin"
  spec.executables = ["vitals"]
  spec.require_paths = ["lib"]

  # CLI framework
  spec.add_dependency "thor", "~> 1.3"

  # Analysis tools (Phase 3)
  spec.add_dependency "rubocop", "~> 1.60"
  spec.add_dependency "reek", "~> 6.3"
  spec.add_dependency "rubycritic", "~> 4.9"
  spec.add_dependency "flog", "~> 4.8"
  spec.add_dependency "simplecov", "~> 0.22"

  # CLI formatting - add these in Phase 5 when implementing reporters
  # spec.add_dependency "tty-box", "~> 0.7"
  # spec.add_dependency "tty-table", "~> 0.12"
  # spec.add_dependency "pastel", "~> 0.8"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
