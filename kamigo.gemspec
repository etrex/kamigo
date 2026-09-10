$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "kamigo/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "kamigo"
  spec.version     = Kamigo::VERSION
  spec.authors     = ["etrex"]
  spec.email       = ["et284vu065k3@gmail.com"]
  spec.homepage    = "https://github.com/etrex/kamigo"
  spec.summary     = "a chatbot framework based on rails"
  spec.description = "a chatbot framework based on rails"
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "docs/1.0.md", "docs/performance-1.0.md", "MIT-LICENSE", "Rakefile", "README.md"]

  # Rails 8.1 JSON decoder passes positional options; json 3 requires keywords.
  spec.add_dependency "json", ">= 2.0", "< 3"
  spec.required_ruby_version = ">= 4.0"
  spec.add_dependency "rails", "~> 8.1", ">= 8.1.3.1"
  spec.add_dependency "kamiliff", "~> 1.0"
  spec.add_dependency "kamiflex", "~> 1.0"
  spec.add_development_dependency "sqlite3", ">= 2.1"
  spec.add_development_dependency "pg", ">= 1.5"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "benchmark"
end
