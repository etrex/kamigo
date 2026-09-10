# frozen_string_literal: true
require "active_support/notifications"
module Kamigo
  class Unauthorized < StandardError; end
  class UnknownHandler < StandardError; end
  class UnsupportedHandoff < StandardError; end

  # Handlers are factories: never share mutable controller/request state.
  class Dispatcher
    def initialize(router:, handlers:, policy:)
      @router, @handlers, @policy = router, handlers.transform_keys(&:to_s).freeze, policy
    end

    def call(event, context: Context.new)
      target = @router.resolve(event, context: context)
      return nil unless target
      factory = @handlers.fetch(target) { raise UnknownHandler, target }
      raise Unauthorized, target unless @policy.call(context, target, event)
      ActiveSupport::Notifications.instrument("dispatch.kamigo", platform: event.platform, target: target) do
        factory.call.call(event: event, context: context)
      end
    end
  end
end
