# Kamigo Development Guide

## Build/Test Commands
- Install dependencies: `bundle install`
- Run all tests: `bundle exec rake test`
- Run a single test: `bundle exec ruby -I test test/path/to/test_file.rb -n test_method_name`
- Generate documentation: `bundle exec rake rdoc`
- Build gem: `bundle exec rake build`

## Code Style Guidelines
- **Formatting**: Use 2-space indentation, no trailing whitespace
- **Naming**: Use snake_case for methods/variables, CamelCase for classes/modules
- **Modules**: Group functionality in modules under the `Kamigo` namespace
- **Classes**: Follow single responsibility principle
- **Method Length**: Keep methods focused and under 15 lines
- **Error Handling**: Use Ruby exceptions with descriptive messages
- **Configuration**: Use mattr_accessor for module configuration
- **Environment Variables**: Use ENV for configuration, with defaults
- **Dependencies**: Specify version constraints in gemspec
- **Documentation**: Document public APIs with clear comments

## LINE Integration
- Use environment variables for LINE credentials
- Delegate LINE login configuration to Kamiliff
- Follow LINE Messaging API best practices