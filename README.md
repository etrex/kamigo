# Kamigo 1.0 (in development)

Rails-first, multi-platform chatbot framework. Breaking rewrite; old routing,
controller and scaffold APIs are removed. Source version 1.0.0 is not a release.

LINE and Telegram adapters are included. Other verified transports can subclass
the platform boundary and register their own template suffix/DSL (for example
`notice.slack.erb`) without changing the router, identity or authorization core.

Ruby 4.0.6, Rails 8.1.3.1; local sibling Kamiflex/Kamiliff 1.0 gems.
See [integration guide](docs/1.0.md) and [performance record](docs/performance-1.0.md).

```sh
bundle install
bundle exec rake test
bundle exec ruby benchmark/router.rb
```

Tests cover the new v1 contract; historical dummy application tests are not v1 acceptance.
No production migration or release has occurred.
