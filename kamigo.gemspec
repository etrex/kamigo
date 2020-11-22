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

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 5.0.0"
  spec.add_dependency "kamiliff", ">= 0.20.0"
  spec.add_dependency "kamiflex", ">= 0.11.0"
  spec.add_dependency "line-bot-api", ">= 1.5"
  spec.add_development_dependency "sqlite3"
end
